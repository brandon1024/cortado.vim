" Filter string elements from `list` while elements match pattern `patt`,
" returning a tuple [count, filtered-list].
function! test_utils#lists#FilterWhileMatching(input, patt) abort
	let l:result = a:input

	while len(l:result) && match(l:result[0], a:patt) >= 0
		let l:result = l:result[1:-1]
	endwhile

	return [len(a:input) - len(l:result), l:result]
endfunction

