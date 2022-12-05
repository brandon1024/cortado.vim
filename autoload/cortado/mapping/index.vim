" Initialize plugin mappings for managing the index.
function! cortado#mapping#index#init() abort
	nmap <silent> <Plug>(cortado-index:dir)     :call cortado#plugin#command('index', 'dir')<CR>
	nmap <silent> <Plug>(cortado-index:buffer)  :call cortado#plugin#command('index', 'buffer')<CR>
	nmap <silent> <Plug>(cortado-index:save)    :call cortado#plugin#command('index', 'save')<CR>
	nmap <silent> <Plug>(cortado-index:recover) :call cortado#plugin#command('index', 'recover')<CR>
	nmap <silent> <Plug>(cortado-index:clear)   :call cortado#plugin#command('index', 'clear')<CR>
endfunction
