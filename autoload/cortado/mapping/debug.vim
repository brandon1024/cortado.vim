" Initialize plugin mappings for interacting with the debugger.
function! cortado#mapping#debug#init() abort
	nmap <silent> <Plug>(cortado-debug:quit)      :call cortado#plugin#command('debug', 'quit')<CR>
	nmap <silent> <Plug>(cortado-debug:resume)    :call cortado#plugin#command('debug', 'resume')<CR>
	nmap <silent> <Plug>(cortado-debug:step-over) :call cortado#plugin#command('debug', 'step-over')<CR>
	nmap <silent> <Plug>(cortado-debug:step-into) :call cortado#plugin#command('debug', 'step-into')<CR>
	nmap <silent> <Plug>(cortado-debug:step-out)  :call cortado#plugin#command('debug', 'step-out')<CR>
	nmap <silent> <Plug>(cortado-debug:break)     :call cortado#plugin#command('debug', 'break')<CR>
	nmap <silent> <Plug>(cortado-debug:frames)    :call cortado#plugin#command('debug', 'frames')<CR>
	nmap <silent> <Plug>(cortado-debug:variables) :call cortado#plugin#command('debug', 'variables')<CR>
	nmap <silent> <Plug>(cortado-debug:print)     :call cortado#plugin#command('debug', 'print')<CR>
endfunction

