" Run checkstyle on file or directory `path`, parsing output and populating
" the quickfix list.
function! cortado#checkstyle#run(path = '.') abort
	let l:utils = cortado#internal#util#new()

	let l:checkstyle_lib = s:find_checkstyle()
	let l:checkstyle_config = s:find_config()

	if l:checkstyle_lib == v:null
		return l:utils.warn('could not find usable checkstyle installation: "' .
			\ g:cortado_checkstyle_lib_path . '"')
	endif

	if l:checkstyle_config == v:null
		return l:utils.warn('could not find usable checkstyle config: "' .
			\ g:cortado_checkstyle_config_file . '"')
	endif

	let l:path = (a:path == '%' ? expand('%') : a:path)

	call setqflist([], 'r')

	let l:job_opts = {
		\ 'out_cb': function('s:stdout_cb'),
		\ 'exit_cb': function('s:exit_cb'),
		\ 'in_io': 'null'
	\ }
	let l:job = job_start(['java',
		\ '-jar', l:checkstyle_lib,
		\ 'com.puppycrawl.tools.checkstyle.Main',
		\ '-c', l:checkstyle_config,
		\ '-f', 'plain',
		\ l:path], l:job_opts)

	echo 'cortado: running checkstyle scan: ' . l:path
endfunction

" Parse a line of output and append to the quickfix list.
function! s:stdout_cb(channel, msg) abort
	let l:matches = matchlist(a:msg, '\(\[.\+\]\) \([^:]\+\):\(\d\+\):\(\d\+\): \(.*\)')
	if !empty(l:matches)
		call setqflist([{
			\ 'filename': l:matches[2],
			\ 'lnum': l:matches[3],
			\ 'col': l:matches[4],
			\ 'text': l:matches[1] . ' ' . l:matches[5]
		\ }], 'a')
	endif
endfunction

" Notify user of checkstyle job completion.
function! s:exit_cb(job, status) abort
	let l:progress = cortado#internal#progress#new()
	let l:utils = cortado#internal#util#new()

	if a:status != 0
		return l:utils.warn('checkstyle exited with status ' . a:status)
	endif

	let l:handle = l:progress.show('checkstyle completed successfully with ' .
		\ len(getqflist()) . ' errors (see quickfix)')
	call l:progress.complete(l:handle)
endfunction

" Lookup the checkstyle jar, returning v:null if the file is not readable.
function! s:find_checkstyle() abort
	return s:file_exists(g:cortado_checkstyle_lib_path)
endfunction

" Lookup the checkstyle config, returning v:null if the file is not readable.
function! s:find_config() abort
	return s:file_exists(g:cortado_checkstyle_config_file)
endfunction

" Lookup `file`, returning v:null if the file is not readable.
function! s:file_exists(file) abort
	return (a:file == v:null || !filereadable(a:file)) ? v:null : a:file
endfunction

