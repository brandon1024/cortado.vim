if exists('g:loaded_java_sort_imports_plugin')
	finish
endif
let g:loaded_java_sort_imports_plugin = 1

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

command! JavaSortImports call java_sort_imports#JavaSortImports()

