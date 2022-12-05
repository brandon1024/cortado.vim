" Create a new popup handle.
function! cortado#internal#popup#new() abort
	let l:handle = {}

	let l:handle.at_cursor = function('s:at_cursor')
	let l:handle.status_message = function('s:status_message')
	let l:handle.entry_table_new = function('s:entry_table_new')
	let l:handle.entry_table_add_row = function('s:entry_table_add_row')
	let l:handle.entry_table_build = function('s:entry_table_build')

	return l:handle
endfunction

" Show a popup at the cursor, requesting a selection from the user.
"
" `entries` is a list of lists, where each entry is a set of popup entries.
" It's possible to cycle through different information with the h/l
" <left>/<right> keys. You can use `entry_table_*()` to build these entries.
"
" `callback` is invoked when an entry is selected by the user, and accepts a
" single argument, the index of the selected entry.
"
" Returns the popup window ID.
function! s:at_cursor(title, entries, callback) abort
	let l:state = 0

	function! s:popup_menu_cb(id, result) abort closure
		if a:result <= 0
			return
		endif

		if a:result > len(a:entries)
			throw 'bug: unexpected result in popup callback "' . a:result. '"'
		endif

		call a:callback(a:result - 1)
	endfunction

	function! s:popup_menu_filter_cb(id, key) abort closure
		if a:key == 'l' || a:key == "\<Right>"
			let l:state = s:rotate_entries(a:id, l:state + 1, a:entries)
			return 1
		elseif a:key == 'h' || a:key == "\<Left>"
			let l:state = s:rotate_entries(a:id, l:state - 1, a:entries)
			return 1
		elseif a:key == "\<Tab>"
			return popup_filter_menu(a:id, "\<CR>")
		else
			return popup_filter_menu(a:id, a:key)
		endif
	endfunction

	return popup_create(a:entries[l:state], {
		\ 'line': 'cursor+1',
		\ 'col': 'cursor',
		\ 'title': a:title,
		\ 'wrap': v:false,
		\ 'moved': 'word',
		\ 'cursorline': 1,
		\ 'filter': function('s:popup_menu_filter_cb'),
		\ 'callback': function('s:popup_menu_cb')
	\ })
endfunction

" Show a status message popup in the bottom right corner of the screen.
" `message` is the initial status message. Use popup_settext() to update the
" status text, and popup_close() to close the popup.
"
" Returns the popup window ID.
function! s:status_message(message) abort
	return popup_create(a:message, {
		\ 'pos': 'botright',
		\ 'line': &lines,
		\ 'col': &columns,
		\ 'maxwidth': 80,
		\ 'minwidth': 80
	\ })
endfunction

" Rotate the entries in the popup, and return `mode`.
function! s:rotate_entries(id, mode, entries) abort
	let l:mode = (a:mode + len(a:entries)) % len(a:entries)
	call popup_settext(a:id, a:entries[a:mode])

	return l:mode
endfunction

" Build a new popup entry table. Used to space text content into aligned
" columns with text properties.
function! s:entry_table_new() abort
	return { 'rows': [], 'col_widths': [] }
endfunction

" Add a single row to the entry table. Each entry in `columns` is a a list of
" 1 or two items:
"   [<text>], or
"   [<text>, <prop name>]
function! s:entry_table_add_row(table, columns) abort
	let l:row = []
	for index in range(len(a:columns))
		let l:column = a:columns[index]

		let l:text = get(l:column, 0, '')
		let l:prop = get(l:column, 1, v:null)
		let l:col_data = extend({ 'text': l:text },
			\ l:prop != v:null ? { 'prop': l:prop } : {})

		call add(l:row, l:col_data)

		" adjust column width
		if index >= len(a:table['col_widths'])
			call add(a:table['col_widths'], len(l:text))
		else
			let a:table['col_widths'][index] = max([a:table['col_widths'][index], len(l:text)])
		endif
	endfor

	call add(a:table['rows'], l:row)
endfunction

" Build a list of popup entries (that can be passed to popup_settext()) from
" an entry table.
function! s:entry_table_build(table) abort
	let l:rows = a:table['rows']
	let l:col_widths = a:table['col_widths']

	let l:results = []
	for index in range(len(l:rows))
		let l:columns = l:rows[index]

		let l:text = ''
		let l:props = []
		for col_idx in range(len(l:columns))
			let l:column = l:columns[col_idx]
			let l:col_text = l:column['text']
			let l:col_width = l:col_widths[col_idx]

			if has_key(l:column, 'prop')
				call add(l:props, {
					\ 'col': len(l:text) + 1,
					\ 'length': len(l:col_text),
					\ 'type': l:column['prop']
				\ })
			endif

			let l:text .= l:col_text . repeat(' ', l:col_width - len(l:col_text))
		endfor

		call add(l:results, { 'text': l:text, 'props': l:props })
	endfor

	return l:results
endfunction

