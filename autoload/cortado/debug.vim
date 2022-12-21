" Launch a debugging session. `address` is the address of the remote JVM to
" attach to. All remaining args are paths to directories that contain source
" files.
function! cortado#debug#launch_session(address, ...) abort
	let l:debugging = cortado#internal#debug#session#new()
	let l:debugging_win = cortado#internal#debug#win#new()
	let l:debugging_state = cortado#internal#debug#state#new()
	let l:utils = cortado#internal#util#new()

	if exists('s:session_handle')
		return l:utils.warn('cannot start debugging session, session already started')
	endif

	if !executable('jdb')
		return l:utils.warn('cannot start debugging session, jdb is not on the $PATH')
	endif

	let l:current_win = win_getid()
	let l:debug_win = l:debugging_win.open()

	let s:session_handle = {
		\ 'win': l:debug_win,
		\ 'state': l:debugging_state.new(),
		\ 'session': l:debugging.launch_session(a:address, {
			\ 'win': l:debug_win,
			\ 'sources': a:000,
			\ 'on_exit_cb': function('s:on_exit'),
			\ 'on_stop_cb': function('s:on_stop')
		\ })
	\ }

	call win_gotoid(l:current_win)
endfunction

" Terminate a debugging session.
function! cortado#debug#quit_session() abort
	if s:session_active()
		call s:session_handle.session.end_session()
		call s:session_handle.state.reset()
		unlet s:session_handle
	endif
endfunction

" Continue execution.
function! cortado#debug#resume() abort
	if s:session_active()
		call s:session_handle.session.send_continue()
		call s:session_handle.state.remove_program_counter()
	endif
endfunction

" Step over the current instruction.
function! cortado#debug#step_over() abort
	if s:session_active()
		call s:session_handle.session.send_step_over()
	endif
endfunction

" Step into a function call.
function! cortado#debug#step_into() abort
	if s:session_active()
		call s:session_handle.session.send_step_into()
	endif
endfunction

" Step out of a function call.
function! cortado#debug#step_out() abort
	if s:session_active()
		call s:session_handle.session.send_step_out()
	endif
endfunction

" Toggle a breakpoint.
function! cortado#debug#break() abort
	if s:session_active()
		let l:breakpoint = s:get_qualified_cursor_pos()

		if !s:session_handle.state.has_breakpoint(l:breakpoint)
			call s:session_handle.state.add_breakpoint(l:breakpoint)
			call s:session_handle.session.send_set_breakpoint(l:breakpoint)
		else
			call s:session_handle.state.remove_breakpoint(l:breakpoint)
			call s:session_handle.session.send_clear_breakpoint(l:breakpoint)
		endif
	endif
endfunction

" Show the call stack.
function! cortado#debug#frames() abort
	if s:session_active()
		call s:session_handle.session.send_where()
	endif
endfunction

" Show all local variables, method arguments and fields.
function! cortado#debug#variables() abort
	if s:session_active()
		call s:session_handle.session.send_locals()
	endif
endfunction

" Evaluate an expression.
function! cortado#debug#evaluate() abort
	if s:session_active()
		call s:session_handle.session.send_print(input('jdb >>> '))
	endif
endfunction

" Print variable under cursor.
function! cortado#debug#print() abort
	if s:session_active()
		call s:session_handle.session.send_dump(expand('<cword>'))
	endif
endfunction

" Get the fully-qualitied line number of the cursor, suitable to be passed to
" jdb in a `stop at`.
function! s:get_qualified_cursor_pos() abort
	let l:java = cortado#internal#java#new()
	let l:utils = cortado#internal#util#new()

	if &filetype != 'java'
		return l:utils.warn('cannot set/unset breakpoint, unexpected filetype "' . &filetype . '"')
	endif

	" best effort: this won't work for nested classes
	let l:package = l:java.get_package()
	let l:class_name = fnamemodify(expand('%'), ':t:r')
	let l:lnum = line('.')

	let l:breakpoint = join(l:utils.flatten([l:package, l:class_name]), '.')
	return l:breakpoint . ':' . l:lnum
endfunction

" Check if a debug session is active. Returns true if active, false otherwise.
function! s:session_active() abort
	let l:utils = cortado#internal#util#new()

	if !exists('s:session_handle')
		call l:utils.warn('no debugging sessions are active')
		return v:false
	endif

	return v:true
endfunction

" Invoked when the underlying JDB process exits.
function! s:on_exit(status) abort
	let l:utils = cortado#internal#util#new()

	if a:status != 0
		call l:utils.warn('jdb exited abnormally (' . a:status . ')')
	endif

	call cortado#debug#quit_session()
endfunction

" Invoked when execution of the remote application stops. Positions the cursor
" and adds an indicator in the sign column.
function! s:on_stop(class, lnum) abort
	if s:session_active()
		let l:jumper = cortado#internal#debug#jump#new()

		if l:jumper.jump_to(a:class, a:lnum)
			call s:session_handle.state.move_program_counter('%', a:lnum)
		else
			call s:session_handle.state.remove_program_counter()
		endif
	endif
endfunction

