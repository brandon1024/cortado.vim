" Entrypoint for the plugin.
function! cortado#plugin#command(cmd, ...) abort
	let l:utils = cortado#internal#util#new()

	let l:cmd_tree = s:build_cmd_tree()

	let l:args = l:utils.flatten([a:cmd, a:000])
	for index in range(len(l:args))
		let l:arg = l:args[index]

		if !has_key(l:cmd_tree, l:arg)
			return l:utils.warn('unexpected argument: ' . l:arg)
		endif

		if type(l:cmd_tree[l:arg]) == v:t_func
			return l:cmd_tree[l:arg](l:args[index+1:-1])
		endif

		let l:cmd_tree = l:cmd_tree[l:arg]
	endfor

	" no more args
	if has_key(l:cmd_tree, '') && type(l:cmd_tree['']) == v:t_func
		return s:execute_cmd(l:cmd_tree[''], [])
	endif

	return l:utils.warn('not enough arguments')
endfunction

" Completion for the :Cortado command.
function! cortado#plugin#command_completion(lead, cmdline, pos) abort
	let l:cmd_tree = s:build_cmd_tree()
	
	let l:args = split(a:cmdline[0:a:pos])[1:-1]
	if empty(l:args)
		return keys(l:cmd_tree)
	endif

	let l:head = l:args[0:-2]
	for index in range(len(l:head))
		let l:arg = l:head[index]

		if !has_key(l:cmd_tree, l:arg) || type(l:cmd_tree[l:arg]) == v:t_func
			return []
		endif

		let l:cmd_tree = l:cmd_tree[l:arg]
	endfor

	let l:tail = l:args[-1]
	if has_key(l:cmd_tree, l:tail)
		if type(l:cmd_tree[l:tail]) == v:t_func
			return []
		endif

		return keys(l:cmd_tree[l:tail])
			\ ->map({ idx, val -> val . ' ' })
	endif

	return keys(l:cmd_tree)
		\ ->filter({ idx, val -> stridx(val, l:tail) == 0})
		\ ->map({ idx, val -> val . ' ' })
endfunction

" Execute a callback function (lambda). Works around Vim's strict variable
" naming requirements.
function! s:execute_cmd(fn, args) abort
	return a:fn(a:args)
endfunction

" Build a dictionary (tree) representing all available options. Leafs are
" lambda functions executing the command.
function! s:build_cmd_tree() abort
	return {
		\ 'imports': {
		\ 	'add': { args -> cortado#import#keyword(get(args, 0, '')) },
		\ 	'sort': { args -> cortado#import#sort() },
		\ 	'optimize': { args -> cortado#import#optimize() },
		\ },
		\ 'index': {
		\ 	'': { args -> cortado#index#buffer() },
		\ 	'buffer': { args -> cortado#index#buffer(get(args, 0, '%')) },
		\ 	'dir': { args -> cortado#index#directory(get(args, 0, v:null)) },
		\ 	'save': { args -> cortado#index#save() },
		\ 	'recover': { args -> cortado#index#recover() },
		\ 	'clear': { args -> cortado#index#clear() },
		\ },
		\ 'insert-var': { args -> cortado#internal#template#var#insert() },
		\ 'debug': {
		\ 	'launch': { args -> cortado#debug#launch_session(args[0], args[1:-1]) },
		\ 	'quit': { args -> cortado#debug#quit_session() },
		\ 	'resume': { args -> cortado#debug#resume() },
		\ 	'step-over': { args -> cortado#debug#step_over() },
		\ 	'step-into': { args -> cortado#debug#step_into() },
		\ 	'step-out': { args -> cortado#debug#step_out() },
		\ 	'break': { args -> cortado#debug#break() },
		\ 	'frames': { args -> cortado#debug#frames() },
		\ 	'variables': { args -> cortado#debug#variables() },
		\ 	'eval': { args -> cortado#debug#evaluate() },
		\ 	'print': { args -> cortado#debug#print() },
		\ }
	\ }
endfunction

