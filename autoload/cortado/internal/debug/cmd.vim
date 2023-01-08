" Create a new jdb cmd builder handle.
function! cortado#internal#debug#cmd#new() abort
	let l:handle = {}

	let l:handle.resume = function('s:resume')

	return l:handle
endfunction

" Build a command to resume execution.
function! s:resume() abort
	return 'cont'
endfunction

" Build a command to set or clear a breakpoint.
function! s:breakpoint(fq_name, lnum) abort
	return {
		\ 'set': { -> ['stop at', join([a:fq_name, a:lnum], ':')] },
		\ 'clear': { -> ['clear', join([a:fq_name, a:lnum], ':')] }
	\ }
endfunction

" Build a command to step into a function call, over an instruction, or out of
" a function call.
function! s:step() abort
	return {
		\ 'into': { -> 'step' },
		\ 'over': { -> 'next' },
		\ 'out': { -> 'step up' }
	\ }
endfunction

" Build a command to show the call stack.
function! s:stacktrace() abort
	return 'where'
endfunction

" Build a command to show fields, local variables and method arguments.
function! s:state() abort
	return 'locals'
endfunction

" Build a command to show source code at the cursor.
function! s:context() abort
	return 'list'
endfunction

" Build a command to evaluate an expression.
function! s:evaluate(expr) abort
	return ['dump', a:expr]
endfunction

