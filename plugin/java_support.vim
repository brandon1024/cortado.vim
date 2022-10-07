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

" By default, enable indexing progress.
if !exists('g:java_import_index_progress')
	let g:java_import_index_progress = 1
endif

" By default, when saving and loading an index, it's read from
" ${HOME}/.cache/java-support/.idx
if !exists('g:java_import_index_path')
	let g:java_import_index_path = $HOME . '/.cache/java-support/.idx'
endif

command! -nargs=* Java call java_support#plugin#Command(<f-args>)

