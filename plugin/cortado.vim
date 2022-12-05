if exists('g:loaded_cortado_plugin')
	finish
endif
let g:loaded_cortado_plugin = 1

" The default order for java imports.
if !exists('g:cortado_import_order')
	let g:cortado_import_order = [
		\ { 'static': 1, 'packages': [] },
		\ { 'static': 0, 'packages': ['java.', 'javax.'] },
		\ { 'static': 0, 'packages': [] }]
endif

" By default, insert empty lines between import groups.
if !exists('g:cortado_import_space_group')
	let g:cortado_import_space_group = 1
endif

" By default, don't group imports into wildcard.
" Allowed values:
" - (< 0): remove any wildcard imports, imports must be fixed by user
" - (= 0): keep wildcard imports, don't merge imports in same package
" - (> 0): merge imports in same package into wildcard import
if !exists('g:cortado_import_wildcard_count')
	let g:cortado_import_wildcard_count = 0
endif

" By default, filter imports that are in the same package as the current java
" file.
if !exists('g:cortado_import_filter_same_package')
	let g:cortado_import_filter_same_package = 1
endif

" By default, always show popup.
if !exists('g:cortado_import_popup_show_always')
	let g:cortado_import_popup_show_always = 1
endif

" By default, enable indexing progress.
if !exists('g:cortado_progress_disabled')
	let g:cortado_progress_disabled = 0
endif

" By default, when saving and loading an index, it's read from
" ${HOME}/.cache/cortado.vim/.idx
if !exists('g:cortado_import_index_path')
	let g:cortado_import_index_path = $HOME . '/.cache/cortado.vim/.idx'
endif

" By default, make all variable declarations 'final'.
if !exists('g:cortado_insert_var_declare_final')
	let g:cortado_insert_var_declare_final = 1
endif

" By default, define plugin mappings.
if !exists('g:cortado_plug_mappings_disable')
	let g:cortado_plug_mappings_disable = 0
endif

command! -nargs=* -complete=customlist,cortado#plugin#command_completion Cortado
	\ call cortado#plugin#command(<f-args>)

augroup cortado_filetype_autocmd_group
	autocmd!
	autocmd FileType java call cortado#mapping#plugin#init()
augroup END

