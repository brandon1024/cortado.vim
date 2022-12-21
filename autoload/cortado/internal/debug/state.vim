" Create a new debug state handle.
function! cortado#internal#debug#state#new() abort
	let l:handle = {}

	let l:handle.new = function('s:new')

	return l:handle
endfunction

" Initialize the debugger state, returning a handle to that newly allocated state.
function! s:new() abort
	let l:signs = cortado#internal#sign#new()

	let l:state = {}
	let l:state.add_breakpoint = function('s:add_breakpoint', [l:state])
	let l:state.remove_breakpoint = function('s:remove_breakpoint', [l:state])
	let l:state.has_breakpoint = function('s:has_breakpoint', [l:state])
	let l:state.move_program_counter = function('s:move_program_counter', [l:state])
	let l:state.remove_program_counter = function('s:remove_program_counter', [l:state])
	let l:state.reset = function('s:reset', [l:state])

	let l:state._breakpoints = []
	let l:state._breakpoint_signs = []
	let l:state._breakpoint_sign_name =
		\ l:signs.define('cortado#debug#breakpoint', '●', 'WarningMsg', 'CursorLine')
	let l:state._pc_sign_name =
		\ l:signs.define('cortado#debug#pc', '→', 'LineNr', 'CursorLine')

	return l:state
endfunction

" Add a breakpoint. Throws an error if this breakpoint already exists.
function! s:add_breakpoint(state, breakpoint) abort
	let l:signs = cortado#internal#sign#new()

	if a:state.has_breakpoint(a:breakpoint)
		throw 'bug: breakpoint already set'
	endif

	call add(a:state._breakpoints, a:breakpoint)
	call add(a:state._breakpoint_signs, l:signs.place(
		\ a:state._breakpoint_sign_name, 'cortado#breakpoints', '%', line('.'), 10))
endfunction

" Removes a breakpoint. Throws an error if this breakpoint doesn't exist.
function! s:remove_breakpoint(state, breakpoint) abort
	let l:signs = cortado#internal#sign#new()

	if !a:state.has_breakpoint(a:breakpoint)
		throw 'bug: breakpoint not set'
	endif

	let l:idx = index(a:state._breakpoints, a:breakpoint)
	call remove(a:state._breakpoints, l:idx)
	call l:signs.remove('cortado#breakpoints', remove(a:state._breakpoint_signs, l:idx))
endfunction

" Check if a breakpoint has been set.
function! s:has_breakpoint(state, breakpoint) abort
	return index(a:state._breakpoints, a:breakpoint) >= 0
endfunction

" Set or move the program counter to line number `lnum` in buffer `buf`.
function! s:move_program_counter(state, buf, lnum) abort
	let l:signs = cortado#internal#sign#new()

	call l:signs.remove_all('cortado#pc')
	call l:signs.place(a:state._pc_sign_name, 'cortado#pc', a:buf, a:lnum, 11)
endfunction

" Remove the program counter sign.
function! s:remove_program_counter(state) abort
	let l:signs = cortado#internal#sign#new()

	call l:signs.remove_all('cortado#pc')
endfunction

" Clear the state.
function! s:reset(state) abort
	let l:signs = cortado#internal#sign#new()

	call l:signs.remove_all('cortado#breakpoints')
	call l:signs.remove_all('cortado#pc')
	let a:state._breakpoints = []
	let a:state._breakpoint_signs = []
endfunction

