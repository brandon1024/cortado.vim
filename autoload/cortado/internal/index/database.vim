" Create a new index database handle.
function! cortado#internal#index#database#new() abort
	let l:handle = {}

	let l:handle.save = function('s:save')
	let l:handle.recover = function('s:recover')

	return l:handle
endfunction

" Save `tree` to |g:cortado_import_index_path|.
"
" `tree` is flattened to a list of import statements and written to the file.
" This index tree can be reloaded through s:recover().
function! s:save(tree) abort
	let l:trees = cortado#internal#import#tree#new()
	let l:fs = cortado#internal#fs#new()
	let l:utils = cortado#internal#util#new()

	let l:imports = l:utils.flatten([
		\ l:trees.flatten(a:tree, {
			\ 'prefix': 'import static ',
			\ 'postfix': ';',
			\ 'filter': { 's': v:true }
		\ }),
		\ l:trees.flatten(a:tree, {
			\ 'prefix': 'import ',
			\ 'postfix': ';',
			\ 'filter': { 's': v:false }
		\ })
	\ ])

	call l:fs.touch(g:cortado_import_index_path)
	call writefile(l:imports, g:cortado_import_index_path)
endfunction

" Recover the index tree from |g:cortado_import_index_path|, returning the tree.
function! s:recover() abort
	let l:trees = cortado#internal#import#tree#new()
	return l:trees.from_file(g:cortado_import_index_path)
endfunction

