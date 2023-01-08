" Create a new debug job handle.
function! cortado#internal#debug#job#new() abort
	let l:handle = {}

	let l:handle.launch = function('s:launch')

	return l:handle
endfunction

" Launch a JDB job. Returns a reference to the job.
"
" supported options:
" - address: the address of the remote JVM
" - sources: a list of paths to Java source files, passed to the debugger
" - on_exit: a callback invoked when the underlying job terminates
" - on_data: a callback invoked when a line of standard output is available
"   from the job
function! s:launch(opts) abort
	let l:utils = cortado#internal#util#new()

	let l:handle = {}

	let l:handle.send_cmd = function('s:send_cmd', [l:handle])
	let l:handle.is_dead = function('s:is_dead', [l:handle])

	let l:handle._opts = a:opts
	let l:handle._data = ''

	let l:job_opts = {
		\ 'in_mode': 'raw',
		\ 'out_mode': 'raw',
		\ 'err_mode': 'raw',
		\ 'out_cb': function('s:on_stdout', [l:handle]),
		\ 'err_cb': function('s:on_stderr', [l:handle]),
		\ 'exit_cb': function('s:on_exit', [l:handle]),
	\ }
	let l:handle._job = job_start(['jdb',
		\ '-sourcepath', join(l:utils.flatten(a:opts.sources), ':'),
		\ '-attach', a:opts.address], l:job_opts)
return l:handle
endfunction

" Send a command to the JDB job via stdin.
function! s:send_cmd(handle, cmd, ...) abort
	let l:utils = cortado#internal#util#new()

	if s:is_dead(a:handle)
		throw 'error: jdb debug session is dead'
	endif

	let l:cmd_args = join(l:utils.flatten([a:cmd, a:000]))
	call ch_sendraw(job_getchannel(a:handle._job), l:cmd_args . "")
endfunction

" Check if the JDB job is dead, returning true if stopped.
function! s:is_dead(handle) abort
	return index(['fail', 'dead'], job_status(a:handle._job)) >= 0
endfunction

" Callback invoked when new data is available on stdout.
function! s:on_stdout(handle, channel, message) abort
	let a:handle._data = a:handle._data . a:message

	let [l:messages, l:end] = s:consume_lines(a:handle._data)
	let a:handle._data = a:handle._data[l:end:-1]

	if has_key(a:handle._opts, 'on_data')
		for line in l:messages
			call a:handle._opts.on_data(line)
		endfor
	endif

	if has_key(a:handle._opts, 'ch')
		" TODO
	endif
endfunction

" Read lines of data from `data`, returning those lines and the index of the
" next character not read.
function! s:consume_lines(data) abort
	let l:messages = []

	let l:last = 0
	let l:lf = stridx(a:data, "", l:last)
	while l:lf != -1
		call add(l:messages, a:data[l:last:l:lf])

		let l:last = l:lf + 1
		let l:lf = stridx(a:data, "", l:last)
	endwhile

	return [l:messages, l:last]
endfunction

" Callback invoked when new data is available on stderr.
function! s:on_stderr(handle, channel, message) abort
endfunction

" Callback invoked when the job terminates.
function! s:on_exit(handle, job, status) abort
	if has_key(a:handle._opts, 'on_exit')
		call a:handle._opts.on_exit(a:status)
	endif
endfunction

