" Create a new jdb session handle.
function! cortado#internal#debug#session#new() abort
	let l:handle = {}

	let l:handle.launch_session = function('s:launch_session')

	return l:handle
endfunction

" Launch a new JDB session. Return a dictionary of function references used to
" interact with the JDB session.
"
" `winid` is the window number that the terminal should be attached to.
" `address` is the address of the JVM to attach to. `root_src_dirs` is a
" colon-delimited list of directories that contains source files of the
" running application. `on_exit_cb` is a callback invoked when the JDB job
" exits accepting a single argument, the exit status.
function! s:launch_session(address, config) abort
	let l:utils = cortado#internal#util#new()

	if !win_gotoid(a:config.win)
		throw 'error: window id ' . a:config.win . ' not found'
	endif

	let l:session_handle = {}
	let l:session_handle.send_continue = function('s:send_continue', [l:session_handle])
	let l:session_handle.send_print = function('s:send_print', [l:session_handle])
	let l:session_handle.send_dump = function('s:send_dump', [l:session_handle])
	let l:session_handle.send_locals = function('s:send_locals', [l:session_handle])
	let l:session_handle.send_list = function('s:send_list', [l:session_handle])
	let l:session_handle.send_where = function('s:send_where', [l:session_handle])
	let l:session_handle.send_set_breakpoint = function('s:send_set_breakpoint', [l:session_handle])
	let l:session_handle.send_clear_breakpoint = function('s:send_clear_breakpoint', [l:session_handle])
	let l:session_handle.send_step_into = function('s:send_step_into', [l:session_handle])
	let l:session_handle.send_step_over = function('s:send_step_over', [l:session_handle])
	let l:session_handle.send_step_out = function('s:send_step_out', [l:session_handle])
	let l:session_handle.end_session = function('s:end_session', [l:session_handle])

	let l:session_handle._dead = v:false
	let l:session_handle._config = a:config

	let l:term_opts = {
		\ 'curwin': v:true,
		\ 'out_cb': function('s:on_stdout', [l:session_handle]),
		\ 'exit_cb': function('s:on_exit', [l:session_handle]),
	\ }

	if g:cortado_debug_close_on_exit
		call extend(l:term_opts, { 'term_finish': 'close' })
	endif

	let l:session_handle._bufnr = term_start(['jdb',
		\ '-sourcepath', join(l:utils.flatten(a:config.sources), ':'),
		\ '-attach', a:address], l:term_opts)

	return l:session_handle
endfunction

" Detach from the session.
function! s:end_session(session_handle) abort
	if a:session_handle._dead
		return
	endif

	let l:job = term_getjob(a:session_handle._bufnr)
	call job_stop(l:job)

	let a:session_handle._dead = v:true
endfunction

" Send a `cont` to the JDB session.
function! s:send_continue(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>cont\<CR>")
endfunction

" Send a `print <expr>` to the JDB session.
function! s:send_print(session_handle, expr) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>print " . a:expr . "\<CR>")
endfunction

" Send a `dump <expr>` to the JDB session.
function! s:send_dump(session_handle, expr) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>dump " . a:expr . "\<CR>")
endfunction

" Send a `locals` to the JDB session.
function! s:send_locals(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>locals\<CR>")
endfunction

" Send a `list` to the JDB session.
function! s:send_list(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>list\<CR>")
endfunction

" Send a `where` to the JDB session.
function! s:send_where(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>where\<CR>")
endfunction

" Send a `stop at <fq_name>:<lnum>` to the JDB session.
function! s:send_set_breakpoint(session_handle, breakpoint) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr,
		\ "\<C-u>stop at " . a:breakpoint . "\<CR>")
endfunction

" Send a `clear <fq_name>:<lnum>` to the JDB session.
function! s:send_clear_breakpoint(session_handle, breakpoint) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr,
		\ "\<C-u>clear " . a:breakpoint . "\<CR>")
endfunction

" Send a `step` to the JDB session.
function! s:send_step_into(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>step\<CR>")
endfunction

" Send a `next` to the JDB session.
function! s:send_step_over(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>next\<CR>")
endfunction

" Send a `step up` to the JDB session.
function! s:send_step_out(session_handle) abort
	if a:session_handle._dead
		throw 'error: jdb debug session is dead'
	endif

	call term_sendkeys(a:session_handle._bufnr, "\<C-u>step up\<CR>")
endfunction

" Callback invoked when data is available on the job's stdout.
function! s:on_stdout(session_handle, channel, message) abort
	let l:matches = matchlist(a:message, '[^,]*, \(.*\)\.\(.*()\), line=\(\d\+\)')
	if !empty(l:matches)
		call a:session_handle._config.on_stop_cb(l:matches[1], l:matches[3])
	endif
endfunction

" Callback invoked when the job exits.
function! s:on_exit(session_handle, job, status) abort
	let a:session_handle._dead = v:true
	call a:session_handle._config.on_exit_cb(a:status)
endfunction

