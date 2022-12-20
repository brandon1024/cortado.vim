" Initialize all plugin mappings.
function! cortado#mapping#plugin#init() abort
	if g:cortado_plug_mappings_disable
		return
	endif

	for name in ['imports', 'index', 'templates', 'checkstyle']
		call cortado#mapping#{name}#init()
	endfor
endfunction

