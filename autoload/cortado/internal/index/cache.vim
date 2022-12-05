let s:idx_tree = v:null
let s:idx = v:null

" Create a new index cache handle.
function! cortado#internal#index#cache#new() abort
	let l:handle = {}

	let l:handle.load = function('s:load')
	let l:handle.clear = function('s:clear')
	let l:handle.get = function('s:get')
	let l:handle.tree = function('s:tree')
	let l:handle.from_buffer = function('s:from_buffer')
	let l:handle.from_dir = function('s:from_dir')

	return l:handle
endfunction

" Load the index from `tree`.
function! s:load(tree) abort
	let l:trees = cortado#internal#import#tree#new()

	let s:idx_tree = a:tree
	let s:idx = l:trees.index(a:tree)
endfunction

" Clear the index to its initial (empty) state.
function! s:clear() abort
	let s:idx_tree = v:null
	let s:idx = v:null
endfunction

" Fetch and return results from the index.
"
" Returns a list of references for `name`, or an empty list if the index is
" empty or doesn't contain `name`.
function! s:get(name) abort
	if s:idx is v:null
		return []
	endif
	
	if has_key(s:idx, a:name)
		return s:idx[a:name]
	endif

	return []
endfunction

" Return the index tree, or v:null if not initialized.
function! s:tree() abort
	if s:idx_tree is v:null
		let l:trees = cortado#internal#import#tree#new()
		return l:trees.new()
	endif

	return s:idx_tree
endfunction

" Build and return a tree from the buffer `buf`.
function! s:from_buffer(buf) abort
	let l:trees = cortado#internal#import#tree#new()
	return l:trees.from_buffer(a:buf)
endfunction

" Build and return a tree by recursively traversing all directories from `dir`.
" `cb` is invoked for every (java) file visited.
function! s:from_dir(dir, cb = v:null) abort
	let l:trees = cortado#internal#import#tree#new()
	let l:fs = cortado#internal#fs#new()

	let l:tree = l:trees.new()
	function! s:visitor(path) abort closure
		if a:path =~ '\.java$'
			call l:trees.merge_from_file(l:tree, a:path)

			if a:cb != v:null
				call a:cb(a:path)
			endif
		endif
	endfunction

	call l:fs.walk_dir(a:dir, { path -> s:visitor(path) })

	return l:tree
endfunction

