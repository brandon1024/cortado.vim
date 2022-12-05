function! test_utils#tags#find_result(type, pkg, results) abort
	for res in a:results
		if res.type == a:type && a:pkg == join(res.fq_name, '.')
			return res
		endif
	endfor

	return v:null
endfunction
