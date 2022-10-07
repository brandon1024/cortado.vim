" Entrypoint for the plugin.
function! java_support#plugin#Command(cmd, ...) abort
	if a:cmd == 'import'
		call java_support#import#JavaImportKeyword(a:0 == 1 ? a:1 : '')
	elseif a:cmd == 'cleanup-imports'
		call java_support#sort#JavaSortImports()
	elseif a:cmd == 'index'
		if a:0 == 0
			return java_support#index#IndexDirectory()
		endif

		let l:subcommand = a:1
		if l:subcommand == 'buffer'
			call java_support#index#IndexBuffer(a:0 == 1 ? a:1 : '')
		elseif l:subcommand == 'dir'
			call java_support#index#IndexDirectory(a:0 == 1 ? a:1 : '')
		elseif l:subcommand == 'save'
			call java_support#index#Save()
		elseif l:subcommand == 'recover'
			call java_support#index#Recover()
		elseif l:subcommand == 'clear'
			call java_support#index#Clear()
		endif
	elseif a:cmd == 'insert-var'
		call java_support#templates#InsertLocalVariable()
	endif
endfunction

