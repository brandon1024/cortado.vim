" Populate the index from the imports in a specific file or buffer.
" Import statements from the buffer are merged into the existing index.
function! cortado#index#buffer(buffer = '%') abort
	call s:load(a:buffer, v:null)
endfunction

" Populate the index from the imports in all files in a directory,
" recursively. Import statements from java files are merged into the existing
" index. If directory is unset, the current working directory is used.
function! cortado#index#directory(directory = v:null) abort
	let l:dir = a:directory == v:null ? getcwd() : a:directory
	call s:load(v:null, l:dir)
endfunction

" Write the index to the database.
function! cortado#index#save() abort
	let l:cache = cortado#internal#index#cache#new()
	let l:database = cortado#internal#index#database#new()
	let l:progress = cortado#internal#progress#new()

	let l:progress_handle = l:progress.show('saving index..')
	call l:database.save(l:cache.tree())

	call l:progress.complete(l:progress_handle, 'index saved!')
endfunction

" Recover the index from the database and merge with the existing index.
function! cortado#index#recover() abort
	let l:trees = cortado#internal#import#tree#new()
	let l:cache = cortado#internal#index#cache#new()
	let l:database = cortado#internal#index#database#new()
	let l:progress = cortado#internal#progress#new()

	let l:progress_handle = l:progress.show('recovering index..')
	call l:cache.load(l:trees.merge_trees(l:cache.tree(), l:database.recover()))

	call l:progress.complete(l:progress_handle, 'index recovered!')
endfunction

" Clear the index.
function! cortado#index#clear() abort
	let l:cache = cortado#internal#index#cache#new()
	let l:progress = cortado#internal#progress#new()

	let l:progress_handle = l:progress.show('clearing index..')

	call l:cache.clear()

	call l:progress.complete(l:progress_handle, 'index cleared!')
endfunction

" Fetch and return results from the index.
function! cortado#index#get(name) abort
	let l:cache = cortado#internal#index#cache#new()
	return l:cache.get(a:name)
endfunction

" Load the index from a buffer or by traversing a directory recursively.
function! s:load(buf, dir) abort
	let l:cache = cortado#internal#index#cache#new()
	let l:trees = cortado#internal#import#tree#new()
	let l:progress = cortado#internal#progress#new()

	let l:progress_handle = l:progress.show('indexing..')

	let l:tree = (a:buf != v:null) ?
		\ l:cache.from_buffer(a:buf) :
		\ l:cache.from_dir(a:dir, { path ->
			\ l:progress.update(l:progress_handle, 'indexing..', path) })

	call l:progress.update(l:progress_handle, 'merging..')
	call l:cache.load(l:trees.merge_trees(l:cache.tree(), l:tree))

	call l:progress.complete(l:progress_handle, 'indexing done!')
endfunction

