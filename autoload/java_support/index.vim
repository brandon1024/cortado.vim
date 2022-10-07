" Populate the index from the imports in a specific file or buffer.
" Import statements from the buffer are merged into the existing index.
function! java_support#index#IndexBuffer(buffer = '%') abort
	let l:progress_handle = java_support#progress#Show()
	call java_support#progress#Update(a:progress_handle, 'indexing..', a:buffer)

	let l:tree = s:BufferIndexLoader(l:progress_handle, a:buffer)

	call java_support#progress#Update(l:progress_handle, 'merging..')
	let l:tree = java_support#import_tree#MergeTrees(l:tree, s:GetIndexTree())

	call java_support#progress#Update(l:progress_handle, 'committing..')
	call s:CommitIndexTree(l:tree, v:false)

	call java_support#progress#Complete(l:progress_handle, 'indexing done!')
endfunction

" Populate the index from the imports in all files in a directory,
" recursively. Import statements from java files are merged into the existing
" index. If directory is unset, the current working directory is used.
function! java_support#index#IndexDirectory(directory = v:null) abort
	let l:progress_handle = java_support#progress#Show()

	let l:dir = a:directory == v:null ? getcwd() : a:directory
	let l:tree = s:RecursiveIndexLoader(l:progress_handle, l:dir)

	call java_support#progress#Update(l:progress_handle, 'merging..')
	let l:tree = java_support#import_tree#MergeTrees(l:tree, s:GetIndexTree())

	call java_support#progress#Update(l:progress_handle, 'committing..')
	call s:CommitIndexTree(l:tree, v:false)

	call java_support#progress#Complete(l:progress_handle, 'indexing done!')
endfunction

" Write the index to `g:java_import_index_path`. The index can be reloaded
" later with #Recover().
function! java_support#index#Save() abort
	let l:progress_handle = java_support#progress#Show()
	call java_support#progress#Update(l:progress_handle, 'saving index..')

	call s:CommitIndexTree(s:GetIndexTree(), v:true, g:java_import_index_path)

	call java_support#progress#Complete(l:progress_handle, 'index saved!')
endfunction

" Recover the index from `g:java_import_index_path` and merge with the
" existing index.
function! java_support#index#Recover() abort
	let l:progress_handle = java_support#progress#Show()
	call java_support#progress#Update(l:progress_handle, 'recovering index..',
		\ g:java_support_index_path)

	let l:tree = s:RecoverIndexTree(g:java_support_index_path)

	call java_support#progress#Update(l:progress_handle, 'merging..')
	let l:tree = java_support#import_tree#MergeTrees(l:tree, s:GetIndexTree())

	call java_support#progress#Update(l:progress_handle, 'committing..')
	call s:CommitIndexTree(l:tree, v:false)

	call java_support#progress#Complete(l:progress_handle, 'index recovered!')
endfunction

" Clear the index.
function! java_support#index#Clear() abort
	let l:progress_handle = java_support#progress#Show()
	call java_support#progress#Update(l:progress_handle, 'clearing index..')

	call s:CommitIndexTree(java_support#import_tree#BuildEmpty(), v:false)

	call java_support#progress#Complete(l:progress_handle, 'index cleared!')
endfunction

" Fetch and return results from the index. Returns a list of references for
" `name`. Returns an empty list if the index is empty, the index doesn't
" contain `name`, or indexing features are disabled.
function! java_support#index#Get(name) abort
	let l:index = s:GetIndex()
	if l:index is v:null
		return []
	endif
	
	if has_key(l:index, a:name)
		return l:index[a:name]
	endif

	return []
endfunction

" Get the index tree, or an empty tree if the tree hasn't been committed yet.
function! s:GetIndexTree() abort
	if !exists('s:idx_tree')
		return java_support#import_tree#BuildEmpty()
	endif

	return s:idx_tree
endfunction

" Get the index, or v:null if the index hasn't been committed yet.
function! s:GetIndex() abort
	if !exists('s:idx')
		return v:null
	endif

	return s:idx
endfunction

" Build an index from `tree` and overwrite the existing index.
"
" When `save` is true, the index is written to `file`.
function! s:CommitIndexTree(tree, save, file = v:null) abort
	let s:idx_tree = a:tree
	let s:idx = java_support#import_tree#Index(a:tree)

	if a:save
		let l:imports = java_support#util#Flatten([
			\ java_support#import_tree#Flatten(a:tree,
				\ { 'prefix': 'import static ', 'postfix': ';', 'filter': { 's': v:true } }),
			\ java_support#import_tree#Flatten(a:tree,
				\ { 'prefix': 'import ', 'postfix': ';', 'filter': { 's': v:false } })
		\ ])
		call s:TouchFile(a:file)
		call writefile(l:imports, a:file)
	endif
endfunction

" Recover an index from `file`, returning a tree. If `file` is empty, return
" an empty tree.
function! s:RecoverIndexTree(file) abort
	if empty(a:file)
		return java_support#import_tree#BuildEmpty()
	endif

	return java_support#import_tree#BuildFromFile(a:file)
endfunction

" Build and return a tree from the buffer `buf`.
function! s:BufferIndexLoader(buf) abort
	let l:tree = java_support#import_tree#BuildFromBuffer(a:buf)

	return l:tree
endfunction

" Load the index by recursively traversing all directories from the current
" working directory.
function! s:RecursiveIndexLoader(progress_handle, directory) abort
	let l:tree = java_support#import_tree#BuildEmpty()
	function! s:Visitor(path) abort closure
		if a:path =~ '\.java$'
			call java_support#import_tree#MergeFromFile(l:tree, a:path)
		endif

		call java_support#progress#Update(a:progress_handle, 'indexing..', a:path)
	endfunction

	call java_support#util#TraverseDirs(a:directory, { path -> s:Visitor(path) })

	return l:tree
endfunction

" Create the index `file`, if one does not already exist.
function! s:TouchFile(file) abort
	let l:dirname = fnamemodify(a:file, ':p:h')
	if !mkdir(l:dirname, 'p')
		return java_support#util#Warn('failed to create index file "'
			\ . l:index_file_path . '"')
	endif

	call writefile([], a:file, 'a')
endfunction

