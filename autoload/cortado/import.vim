" Import a class with name `keyword`.
"
" If `keyword` is provided as a function argument, a popup menu is shown
" allowing the user to select which class to import.
"
" If `keyword` is empty or unset, default to keyword under cursor (<cword>).
"
" If `keyword` is empty and <cword> expands to empty, the imports in the
" current buffer are sorted.
function! cortado#import#keyword(keyword = '') abort
	let l:java = cortado#internal#java#new()
	let l:utils = cortado#internal#util#new()

	if &filetype != 'java'
		return l:utils.warn('cannot import, unexpected filetype "' . &filetype . '"')
	endif

	let l:keyword = a:keyword ? a:keyword : expand('<cword>')
	if empty(l:keyword)
		return cortado#import#sort()
	endif

	" make sure the keyword is a valid java identifier
	if !l:java.is_valid_identifier(l:keyword)
		return l:utils.warn('keyword "' . keyword . '" is not a valid Java identifier')
	endif

	let l:import_tag_results = s:fetch_results(l:keyword)
	if empty(l:import_tag_results)
		return l:utils.warn('cannot import, nothing found for keyword "' . l:keyword . '"')
	endif

	" if there's only one result, don't show popup if configured
	if !g:cortado_import_popup_show_always && len(a:tag_results) == 1
		return s:import_class(a:tag_results[0])
	endif

	call s:import_from_selection(l:keyword, l:import_tag_results)
endfunction

" Sort import statements in the current buffer.
function! cortado#import#sort() abort
	let l:trees = cortado#internal#import#tree#new()
	let l:sorting = cortado#internal#import#sort#new()
	let l:optimizer = cortado#internal#import#optimize#new()
	let l:utils = cortado#internal#util#new()

	if &filetype != 'java'
		return l:utils.warn('cannot sort imports: unexpected filetype "' . &filetype . '"')
	endif

	let l:tree = l:trees.from_buffer('%', v:true)
	let l:tree = l:optimizer.wildcards(l:tree)
	let l:statements = l:sorting.sort(l:tree)

	call l:sorting.write(l:statements)
endfunction

" Build popup entry strings for the given `tag_results`. `mode` is used to
" select a format.
function! s:build_popup_entries(tag_results) abort
	let l:popup =  cortado#internal#popup#new()

	let l:table_1 = l:popup.entry_table_new()
	let l:table_2 = l:popup.entry_table_new()
	let l:table_3 = l:popup.entry_table_new()

	let l:popup_entries = []

	for result in a:tag_results
		" format 0: ' [<static> <kind>] <import> '
		call l:popup.entry_table_add_row(l:table_1, [
			\ [printf(' [%s%s] ', result.s ? 'static ' : '', result.type)],
			\ [join(result.fq_name, '.') . ' ']
		\ ])

		" format 1: ' <short filepath> '
		call l:popup.entry_table_add_row(l:table_2, [
			\ [' ' . pathshorten(result.fname) . ' ']
		\ ])

		" format 2: ' <long filepath> '
		call l:popup.entry_table_add_row(l:table_3, [
			\ [' ' . result.fname . ' ']
		\ ])
	endfor

	return [
		\ l:popup.entry_table_build(l:table_1),
		\ l:popup.entry_table_build(l:table_2),
		\ l:popup.entry_table_build(l:table_3)
	\ ]
endfunction

" Show a popup menu with the possible classes or enums to import, allowing the
" user to select which to import.
function! s:import_from_selection(keyword, tag_results) abort
	let l:popup =  cortado#internal#popup#new()

	let l:title = '  import "' . a:keyword . '"?'
	let l:entries = s:build_popup_entries(a:tag_results)

	call l:popup.at_cursor(l:title, l:entries,
		\ { result -> s:import_class(a:tag_results[result]) })
endfunction

" Import a class with the given fully-qualified class name.
function! s:import_class(tag_result) abort
	let l:trees = cortado#internal#import#tree#new()
	let l:sorting = cortado#internal#import#sort#new()
	let l:optimizer = cortado#internal#import#optimize#new()

	let l:tree = l:trees.from_buffer('%', v:true)
	let l:tree = l:trees.merge(l:tree, a:tag_result.fq_name, { 's': a:tag_result.s })
	let l:tree = l:optimizer.wildcards(l:tree)
	let l:statements = l:sorting.sort(l:tree)

	call l:sorting.write(l:statements)
endfunction

" Fetch import suggestion results from tags and from the index (if enabled).
function! s:fetch_results(keyword) abort
	let l:tags = cortado#internal#tag#new()

	let l:tag_results = l:tags.lookup(a:keyword)

	let l:indexed_results = []
	for indexed in cortado#index#get(a:keyword)
		call add(l:indexed_results, { 'type': 'indexed', 's': indexed.meta.s,
			\ 'fq_name': indexed.fq_name, 'fname': 'unknown' })
	endfor

	" sort results by kind
	let l:tag_results = sort(l:tag_results,
		\ function('cortado#import#result_comparator'))
	let l:indexed_results = sort(l:indexed_results,
		\ function('cortado#import#result_comparator'))

	return cortado#import#merge_filter_duplicate_results(l:tag_results, l:indexed_results)
endfunction

" A comparator for results. Used to sort results in the following order:
" - kind: classes (c,i,a)
" - kind: enums (g,e)
" - kind: methods (m)
" - kind: indexed
" - kind: everything else
function! cortado#import#result_comparator(result1, result2) abort
	let l:recognized_kinds = ['indexed', 'm', 'e', 'g', 'a', 'i', 'c']
	let l:p1 = index(l:recognized_kinds, a:result1['type'])
	let l:p2 = index(l:recognized_kinds, a:result2['type'])

	return (l:p1 == l:p2) ? 0 : (l:p1 < l:p2 ? 1 : -1)
endfunction

" Filter indexed imports that are duplicates of tag imports.
function! cortado#import#merge_filter_duplicate_results(tag_results, index_results) abort
	let l:hashed_tag_results = {}
	for tag_result in a:tag_results
		let l:hashed_tag_results[string(tag_result.fq_name)] = v:true
	endfor

	call filter(a:index_results,
		\ { idx, val -> !has_key(l:hashed_tag_results, string(val.fq_name)) })

	return extend(a:tag_results, a:index_results)
endfunction

