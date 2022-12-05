" Initialize plugin mappings for inserting templates.
function! cortado#mapping#templates#init() abort
	nmap <silent> <Plug>(cortado-templates:var)  :call cortado#plugin#command('insert-var')<CR>
	imap <silent> <Plug>(cortado-templates:var)  <C-o>:call cortado#plugin#command('insert-var')<CR>
endfunction
