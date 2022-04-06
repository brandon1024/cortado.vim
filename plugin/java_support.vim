if exists('g:loaded_java_support_plugin')
	finish
endif
let g:loaded_java_support_plugin = 1

" The default order for java imports.
if !exists('g:java_import_order')
	let g:java_import_order = [
		\ { 'static': 1, 'packages': [] },
		\ { 'static': 0, 'packages': ['java.', 'javax.'] },
		\ { 'static': 0, 'packages': [] }]
endif

" By default, insert empty lines between import groups.
if !exists('g:java_import_space_group')
	let g:java_import_space_group = 1
endif

" By default, don't group imports into wildcard.
" Allowed values:
" - (< 0): remove any wildcard imports, imports must be fixed by user
" - (= 0): keep wildcard imports, don't merge imports in same package
" - (> 0): merge imports in same package into wildcard import
if !exists('g:java_import_wildcard_count')
	let g:java_import_wildcard_count = 0
endif

command! JavaSortImports call sort#JavaSortImports()
command! -nargs=? JavaImportKeyword call import#JavaImportKeyword(<f-args>)

