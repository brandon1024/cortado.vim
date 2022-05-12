" Check if the tree `tree` has a node at `path`. Returns v:true if the node
" exists, otherwise returns v:false.
function! test_utils#tree#HasNode(tree, path) abort
	return len(test_utils#tree#GetMetadataForNode(a:tree, a:path)) ? v:true : v:false
endfunction

" Get the metadata associated with a node in `tree` at path `path`.
" Return a tuple [<leaf node name>, <leaf metadata>]
function! test_utils#tree#GetMetadataForNode(tree, path) abort
	let l:cmps = split(a:path, '\.')
	let l:leading = l:cmps[0:-2]
	let l:leaf = l:cmps[-1]

	let l:node = a:tree
	for cmp in l:leading
		if !has_key(l:node, 'children') || !has_key(l:node.children, cmp)
			return []
		endif

		let l:node = l:node.children[cmp]
	endfor

	if !has_key(l:node, 'leaf') || !has_key(l:node.leaf, l:leaf)
		return []
	endif

	return [l:leaf, l:node.leaf[l:leaf]]
endfunction

