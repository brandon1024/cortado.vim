" Initialize plugin mappings for running checkstyle.
function! cortado#mapping#imports#init() abort
	nmap <silent> <Plug>(cortado-checkstyle:dir)    :call cortado#plugin#command('checkstyle')<CR>
	nmap <silent> <Plug>(cortado-checkstyle:buffer) :call cortado#plugin#command('checkstyle', '%')<CR>
endfunction

