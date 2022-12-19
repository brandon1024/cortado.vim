" Initialize plugin mappings for manipulating import statements.
function! cortado#mapping#imports#init() abort
	nmap <silent> <Plug>(cortado-imports:add)         :call cortado#plugin#command('imports', 'add')<CR>
	nmap <silent> <Plug>(cortado-imports:sort)        :call cortado#plugin#command('imports', 'sort')<CR>
	nmap <silent> <Plug>(cortado-imports:optimize)    :call cortado#plugin#command('imports', 'optimize')<CR>
endfunction

