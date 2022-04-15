" Get the keyword (<cword>) under the cursor.
function! s:GetKeywordUnderCursor() abort
	return expand('<cword>')
endfunction

" Build popup entry strings for the given `tag_results`.
" `mode` is used to select a format.
function! s:BuildPopupEntries(tag_results, mode)
	let l:popup_entries = []
	for result in a:tag_results
		let l:entry = ''
		if a:mode == 0
			let l:entry = printf(' [%s%s] %s ', result.s ? 'static ' : '',
				\ result.type, join(result.fq_name, '.'))
		elseif a:mode == 1
			let l:entry = ' ' . pathshorten(result.fname) . ' '
		elseif a:mode == 2
			let l:entry = ' ' . result.fname . ' '
		else
			echoerr 'bug: unexpected mode ' . a:mode
		endif

		call add(l:popup_entries, l:entry)
	endfor

	return l:popup_entries
endfunction

" Rotate the entries in the popup, and return `mode`.
function! s:RotatePopupEntries(id, mode, tag_results)
	let l:mode = a:mode < 0 ? 2 : (a:mode > 2 ? 0 : a:mode)
	let l:popup_entries = s:BuildPopupEntries(a:tag_results, l:mode)
	call popup_settext(a:id, l:popup_entries)
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
			echoerr 'bug: unexpected result in popup callback "' . a:result. '"'
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
		elseif a:key == 'j'
			return popup_filter_menu(a:id, "\<Down>")
		elseif a:key == 'k'
			return popup_filter_menu(a:id, "\<Up>")
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
	let l:trees = import_tree#BuildFromBuffer(v:true)
	call import_tree#Merge(l:trees, a:tag_result.fq_name, { 's': a:tag_result.s })
	call sort#JavaSortImportsTrees(l:trees)

	echo 'imported "' . join(a:tag_result.fq_name, '.') . '"'
endfunction

" Import a class with name `keyword`. If `keyword` is empty or unset, default
" to keyword under cursor (<cword>).
" If a keyword is provided as a function argument, the first result is
" imported. Otherwise, a popup menu is shown allowing the user to select which
" class to import.
function! import#JavaImportKeyword(keyword = '') abort
	" ensure this is a java file
	if &filetype != 'java'
		echohl WarningMsg |
			\ echo 'cannot import class: unexpected filetype "' . &filetype . '"' |
			\ echohl None
		return
	endif

	if !len(tagfiles())
		echohl WarningMsg |
			\ echo 'cannot import class: missing a tag file' |
			\ echohl None
		return
	endif

	let l:keyword = a:keyword ? a:keyword : s:GetKeywordUnderCursor()
	if l:keyword == ''
		return
	endif

	" make sure the keyword is a valid java identifier
	if !util#IsValidJavaIdentifierComponent(l:keyword)
		echohl WarningMsg |
			\ echo 'keyword "' . keyword . '" is not a valid Java identifier' |
			\ echohl None
		return
	endif

	let l:import_tag_results = tags#Lookup(l:keyword)
	if !len(l:import_tag_results)
		echohl WarningMsg |
			\ echo 'cannot import class: no classes found for keyword "' . l:keyword . '"' |
			\ echohl None
		return
	endif

	call s:ImportFromSelection(l:keyword, l:import_tag_results)
endfunction

