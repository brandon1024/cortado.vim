" Create a new import tree handle.
function! cortado#internal#import#optimize#new() abort
	let l:handle = {}

	let l:handle.wildcards = function('s:wildcards')

	return l:handle
endfunction

function! s:wildcards(tree) abort
	let l:trees = cortado#internal#import#tree#new()

	function! s:tree_node_visitor(node, path, acc) abort
		let a:node.leaf = s:merge_leaf_nodes(a:node.leaf)
	endfunction

	call l:trees.visit_parents(a:tree, function('s:tree_node_visitor'), v:null)

	return a:tree
endfunction

" Merge (or otherwise manipulate) leaf nodes according to configuration
" `g:cortado_import_wildcard_count`.
"
" See documentation for semantics of this option.
function! s:merge_leaf_nodes(leafs) abort
	let l:leafs = extend({}, a:leafs)

	" nuclear: remove and let user fix imports
	if g:cortado_import_wildcard_count < 0
		if has_key(l:leafs, '*')
			call remove(l:leafs, '*')
		endif

		return l:leafs
	endif

	" sane: merge into a wildcard if one already exists
	if g:cortado_import_wildcard_count == 0
		if !has_key(l:leafs, '*')
			return l:leafs
		endif

		" assume non-static; this should be done smarter later
		return { '*': { 's': v:false } }
	endif

	" chaotic evil: merge into a wildcard if over a certain number
	let l:count = len(keys(l:leafs)) - (has_key(l:leafs, '*') ? 1 : 0)
	if l:count >= g:cortado_import_wildcard_count
		" assume non-static; this should be done smarter later
		return { '*': { 's': v:false } }
	endif

	return l:leafs
endfunction
