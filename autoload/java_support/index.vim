" Populate the index.
"
" When `save` is true, the index is written to `g:java_import_index_path`, if
" configured.
"
" When `recover` is true, the index is loaded from `g:java_import_index_path`,
" if configured, and merged with the existing index. Otherwise, the index is
" populated from `buffer`, if non null, or through recursive directory
" traversal from the cwd.
function! java_support#index#Load(save, recover, buffer = v:null) abort
	if !g:java_import_index_enable
		echohl WarningMsg |
			\ echo 'java-support.vim: indexing features are disabled' |
			\ echohl None
		return
	endif

	" lmake sure the index file exists
	let l:index_file_path = g:java_import_index_path . '/.idx'
	if !empty(g:java_import_index_path)
		if !mkdir(g:java_import_index_path, "p")
			echohl WarningMsg |
				\ echo 'java-support.vim: failed to create index save location "' . g:java_import_index_path . '"' |
				\ echohl None
			return
		endif

		" create the file
		call writefile([], l:index_file_path, 'a')
	endif

	if a:save && empty(g:java_import_index_path)
		echohl WarningMsg |
			\ echo 'java-support.vim: index file location unset (g:java_import_index_save)' |
			\ echohl None
		return
	endif

	let l:progress_handle = java_support#progress#Show()
	let l:tree = v:null

	if a:recover
		call java_support#progress#Update(l:progress_handle, 'recovering index..', l:index_file_path)
		let l:tree = s:RecoverIndexTree(l:index_file_path)
	else
		let l:tree = a:buffer != v:null ?
			\ s:BufferIndexLoader(l:progress_handle, a:buffer) : s:RecursiveIndexLoader(l:progress_handle)
	endif

	" merge the tree with what we already have
	call java_support#progress#Update(l:progress_handle, 'merging..')
	let l:tree = java_support#import_tree#MergeTrees(l:tree, s:GetIndexTree())

	" commit, and optionally save to the index file
	call java_support#progress#Update(l:progress_handle, 'committing..')
	call s:CommitIndexTree(l:tree, a:save, l:index_file_path)

	call java_support#progress#Complete(l:progress_handle, 'indexing done!')
endfunction

" Reset the index to its initial (empty) state.
"
" When `save` is true, the empty index is written to `g:java_import_index_path`,
" if configured (clears the cache).
function! java_support#index#Reset(save) abort
	if a:save && empty(g:java_import_index_path)
		echohl WarningMsg |
			\ echo 'java-support.vim: index file location unset (g:java_import_index_save)' |
			\ echohl None
		return
	endif

	call s:CommitIndexTree(java_support#import_tree#BuildEmpty(),
		\ a:save, g:java_import_index_path)
endfunction

" Fetch and return results from the index. Returns a list of references for
" `name`. Returns an empty list if the index is empty, the index doesn't
" contain `name`, or indexing features are disabled.
function! java_support#index#Get(name) abort
	if !g:java_import_index_enable
		return []
	endif

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
function! s:BufferIndexLoader(progress_handle, buf) abort
	let l:tree = java_support#import_tree#BuildFromBuffer(a:buf)
	call java_support#progress#Update(a:progress_handle, 'indexing..', a:buf)

	return l:tree
endfunction

" Load the index by recursively traversing all directories from the current
" working directory.
function! s:RecursiveIndexLoader(progress_handle) abort
	let l:tree = java_support#import_tree#BuildEmpty()
	function! s:Visitor(path) abort closure
		if a:path =~ '\.java$'
			call java_support#import_tree#MergeFromFile(l:tree, a:path)
		endif

		call java_support#progress#Update(a:progress_handle, 'indexing..', a:path)
	endfunction

	call java_support#util#TraverseDirs(getcwd(), { path -> s:Visitor(path) })

	return l:tree
endfunction

