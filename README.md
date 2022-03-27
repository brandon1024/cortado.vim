# java-sort-imports.vim
A Vim plugin that rearranges import statements in Java files.

## Installation
This plugin has no external dependencies, so you can easily install with your
favourite plugin manager.

With [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'brandon1024/java-sort-imports.vim'
```

## Usage
To sort import statements in the current buffer:
```
:JavaSortImports
```

You can add a mapping to make your life a bit easier:
```
nnoremap <silent> <leader>o :JavaSortImports<CR>
```

If you're feeling bold, automatically sort imports before writing the buffer:
```
augroup java_sort_imports
	autocmd!
	autocmd BufWritePre * if &ft == 'java' | call s:JavaSortImports() | endif
augroup END
```

## Configuration
### `g:java_import_order`
A list of dictionaries used to configure how import statements are grouped.

If `static` is true, only static imports are included in the group. Otherwise,
only non-static imports are included in the group.

`packages` is a list of strings matching the beginning of the imported package
path. If empty, all remaining imports are grouped together.

Default:
```
let g:java_import_order = [
	\ { 'static': 1, 'packages': [] },
	\ { 'static': 0, 'packages': ['java.', 'javax.'] },
	\ { 'static': 0, 'packages': [] }]
```

### `g:java_import_space_group`
Insert an empty line between import groups.

Default:
```
let g:java_import_space_group = 1
```

## License
This project is licensed under the MIT license.

