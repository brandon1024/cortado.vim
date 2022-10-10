" Import a class with name `keyword`.
"
" If `keyword` is provided as a function argument, a popup menu is shown
" allowing the user to select which class to import.
"
" If `keyword` is empty or unset, default to keyword under cursor (<cword>).
"
" If `keyword` is empty and <cword> expands to empty, the imports in the
" current buffer are sorted.
function! java_support#import#JavaImportKeyword(keyword = '') abort
	if &filetype != 'java'
		return java_support#util#Warn('cannot import class: unexpected filetype "' . &filetype . '"')
	endif

	let l:keyword = a:keyword ? a:keyword : s:GetKeywordUnderCursor()
	if empty(l:keyword)
		call java_support#sort#JavaSortImports()
		return
	endif

	" make sure the keyword is a valid java identifier
	if !java_support#java#IsValidIdentifier(l:keyword)
		return java_support#util#Warn('keyword "' . keyword . '" is not a valid Java identifier')
	endif

	let l:import_tag_results = s:FetchResults(l:keyword)
	if empty(l:import_tag_results)
		return java_support#util#Warn('cannot import, nothing found for keyword "' . l:keyword . '"')
	endif

	" if there's only one result, don't show popup if configured
	if !g:java_import_popup_show_always && len(a:tag_results) == 1
		return s:ImportClass(a:tag_results[0])
	endif

	call s:ImportFromSelection(l:keyword, l:import_tag_results)
endfunction

" Look for unused imports in a buffer. If 'remove' is true, the unused imports
" are removed. Otherwise, the unused imports are written to the quickfix list.
function! java_support#import#FindUnused(buffer = '%', remove = v:false) abort
	if &filetype != 'java'
		return java_support#util#Warn('cannot import class: unexpected filetype "' . &filetype . '"')
	endif

	" build import tree from the buffer, removing the import statements
	let l:tree = java_support#import_tree#BuildFromBuffer(a:buffer, v:true)

	" index the tree for easier usage lookup in buffer
	let l:indexed_tree = java_support#import_tree#Index(l:tree)

	" ignore star imports in the index
	if has_key(l:indexed_tree, '*')
		call remove(l:indexed_tree, '*')
	endif

	if !a:remove
		call setqflist([], 'r')
	endif

	" find unused imports
	let l:unused = s:FindUnused(a:buffer, l:indexed_tree)
	for fq_name in l:unused
		if a:remove
			call java_support#import_tree#Remove(l:tree, fq_name)
		else
			call setqflist([{
				\ 'bufnr': bufnr(a:buffer),
				\ 'pattern': join(fq_name, '.'),
				\ 'text': join(fq_name, '.')
			\ }], 'a')
		endif
	endfor

	call java_support#sort#JavaSortImportsTrees(l:tree)
endfunction

" From an index, look for usages of each import in the given buffer. Return
" a list of all fully-qualified imports (split into their components) that
" are not referenced in the buffer.
function! s:FindUnused(buffer, index) abort
	let l:unused = []
	for [class_name, entries] in items(a:index)
		" exactly match the classname:
		" - match case sensitive
		" - the character before or after the classname must not be an
		"   indentifier character [^a-zA-Z$_]
		let l:pattern = '\C\(^\|[^a-zA-Z$_]\)' . class_name . '\($\|[^a-zA-Z$_]\)'

		if !java_support#buffer#FindLineMatchingPattern(a:buffer, 1, l:pattern)
			call extend(l:unused, map(entries, {idx, val -> val['fq_name']}))
		endif
	endfor

	return l:unused
endfunction

" Build popup entry strings for the given `tag_results`. `mode` is used to
" select a format.
function! s:BuildPopupEntries(tag_results, mode) abort
	let l:popup_entries = []

	for result in a:tag_results
		\ " format 0: ' [<static> <kind>] <import> '
		\ " format 1: ' <short filepath> '
		\ " format 1: ' <long filepath> '

		let l:formats = [
			\ printf(' [%s%s] %s ', result.s ? 'static ' : '',
				\ result.type, join(result.fq_name, '.')),
			\ ' ' . pathshorten(result.fname) . ' ',
			\ ' ' . result.fname . ' '
		\ ]

		call add(l:popup_entries, l:formats[a:mode])
	endfor

	return l:popup_entries
endfunction

" Rotate the entries in the popup, and return `mode`.
function! s:RotatePopupEntries(id, mode, tag_results) abort
	let l:mode = a:mode < 0 ? 2 : (a:mode > 2 ? 0 : a:mode)
	call popup_settext(a:id, s:BuildPopupEntries(a:tag_results, l:mode))

	return l:mode
endfunction

" Show a popup menu with the possible classes or enums to import, allowing the
" user to select which to import.
function! s:ImportFromSelection(keyword, tag_results) abort
	let l:state = 0

	function! s:PopupMenuCallback(id, result) abort closure
		if a:result <= 0
			return
		endif

		if a:result > len(a:tag_results)
			throw 'bug: unexpected result in popup callback "' . a:result. '"'
		endif

		call s:ImportClass(a:tag_results[a:result - 1])
	endfunction

	function! s:PopupMenuFilterCallback(id, key) abort closure
		if a:key == 'l' || a:key == "\<Right>"
			let l:state = s:RotatePopupEntries(a:id, l:state + 1, a:tag_results)
			return 1
		elseif a:key == 'h' || a:key == "\<Left>"
			let l:state = s:RotatePopupEntries(a:id, l:state - 1, a:tag_results)
			return 1
		elseif a:key == "\<Tab>"
			return popup_filter_menu(a:id, "\<CR>")
		else
			return popup_filter_menu(a:id, a:key)
		endif
	endfunction

	let l:popup_entries = s:BuildPopupEntries(a:tag_results, l:state)
	call popup_create(l:popup_entries, {
		\ 'line': 'cursor+1',
		\ 'col': 'cursor',
		\ 'title': '  import "' . a:keyword . '"?',
		\ 'wrap': v:false,
		\ 'moved': 'word',
		\ 'cursorline': 1,
		\ 'filter': function('s:PopupMenuFilterCallback'),
		\ 'callback': function('s:PopupMenuCallback')
		\ })
endfunction

" Import a class with the given fully-qualified class name.
function! s:ImportClass(tag_result) abort
	let l:trees = java_support#import_tree#BuildFromBuffer('%', v:true)
	call java_support#import_tree#Merge(l:trees, a:tag_result.fq_name, { 's': a:tag_result.s })
	call java_support#sort#JavaSortImportsTrees(l:trees)
endfunction

" Fetch import suggestion results from tags and from the index (if enabled).
function! s:FetchResults(keyword) abort
	let l:tag_results = java_support#tags#Lookup(a:keyword)

	let l:indexed_results = []
	for indexed in java_support#index#Get(a:keyword)
		call add(l:indexed_results, { 'type': 'indexed', 's': indexed.meta.s,
			\ 'fq_name': indexed.fq_name, 'fname': 'unknown' })
	endfor

	" sort results by kind
	let l:tag_results = sort(l:tag_results,
		\ function('java_support#import#ResultComparator'))
	let l:indexed_results = sort(l:indexed_results,
		\ function('java_support#import#ResultComparator'))

	return java_support#import#MergeFilterDuplicateResults(l:tag_results, l:indexed_results)
endfunction

" A comparator for results. Used to sort results in the following order:
" - kind: classes (c,i,a)
" - kind: enums (g,e)
" - kind: methods (m)
" - kind: indexed
" - kind: everything else
function! java_support#import#ResultComparator(result1, result2) abort
	let l:recognized_kinds = ['indexed', 'm', 'e', 'g', 'a', 'i', 'c']
	let l:p1 = index(l:recognized_kinds, a:result1['type'])
	let l:p2 = index(l:recognized_kinds, a:result2['type'])

	return (l:p1 == l:p2) ? 0 : (l:p1 < l:p2 ? 1 : -1)
endfunction

" Filter indexed imports that are duplicates of tag imports.
function! java_support#import#MergeFilterDuplicateResults(tag_results, index_results) abort
	let l:hashed_tag_results = {}
	for tag_result in a:tag_results
		let l:hashed_tag_results[string(tag_result.fq_name)] = v:true
	endfor

	call filter(a:index_results,
		\ { idx, val -> !has_key(l:hashed_tag_results, string(val.fq_name)) })

	return extend(a:tag_results, a:index_results)
endfunction

" Get the keyword (<cword>) under the cursor.
function! s:GetKeywordUnderCursor() abort
	return expand('<cword>')
endfunction

