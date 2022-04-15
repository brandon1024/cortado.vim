# java-support.vim
![vim.ci](https://img.shields.io/github/workflow/status/brandon1024/java-support.vim/vim.ci)
[![Documentation](https://img.shields.io/badge/Documentation-java--support.txt-brightgreen)](https://github.com/brandon1024/java-support.vim/blob/main/doc/java-support.txt)

A Vim plugin for easier editing of Java files. Rearrange, optimize, and
reformat import statements. Import classes easily with the help of tag files.

![](.github/screenshot.png)

<sup>Note: Neovim is not yet supported, but contributions welcome!</sup>

## Installation
This plugin has no external dependencies, so you can easily install with your
favourite plugin manager.

With [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'brandon1024/java-support.vim'
```

## Usage
To sort import statements in the current buffer:
```vim
:JavaSortImports
```

To import a class under the current keyword (or a specific class):
```vim
:JavaImportKeyword
:JavaImportKeyword MyClass
```

The class import functionality relies on the existence of a tags file. The tags
file can be generated with a tool like
[universal-ctags](https://github.com/universal-ctags/ctags). The ctags
generator must smart enough to read Java files correctly (including metadata
like whether it's a class or enum).

You can add a mapping to make your life a bit easier:
```vim
nnoremap <silent> <leader>o :JavaSortImports<CR>
nnoremap <silent> <leader>i :JavaImportKeyword<CR>
```

## Configuration
### `g:java_import_order`
A list of dictionaries used to configure how import statements are grouped.

If `static` is true, only static imports are included in the group. Otherwise,
only non-static imports are included in the group.

`packages` is a list of strings matching the beginning of the imported package
path. If empty, all remaining imports are grouped together.

Default:
```vim
let g:java_import_order = [
	\ { 'static': 1, 'packages': [] },
	\ { 'static': 0, 'packages': ['java.', 'javax.'] },
	\ { 'static': 0, 'packages': [] }]
```

### `g:java_import_space_group`
insert an empty line between import groups.

default:
```vim
let g:java_import_space_group = 1
```

### `g:java_import_wildcard_count`
Configure whether to merge import statements into a single wildcard import. The
value is a number, where:
- `< 0` will remove wildcard import statements altogether (may require
manually adding new import statements),
- `= 0` will keep existing wildcard imports and merge them, but otherwise won't
merge imports,
- `> 0` will merge imports in the same package into a single wildcard import
when the number of imports exceeds the configured value.

The following contrived example demonstrates this behaviour.
```java
// original
import java.io.IOException;
import java.io.SSLException;
import java.io.StringWriter;
import java.io.ObjectInputFilter.Status;
import java.util.List;
import java.util.Collections;
import java.util.*;

// let g:java_import_wildcard_count = -1
import java.io.IOException;
import java.io.ObjectInputFilter.Status;
import java.io.SSLException;
import java.io.StringWriter;
import java.util.Collections;
import java.util.List;

// let g:java_import_wildcard_count = 0
import java.io.IOException;
import java.io.ObjectInputFilter.Status;
import java.io.SSLException;
import java.io.StringWriter;
import java.util.*;

// let g:java_import_wildcard_count = 3
import java.io.*;
import java.io.ObjectInputFilter.Status;
import java.util.Collections;
import java.util.List;
```

Default:
```vim
let g:java_import_wildcard_count = 0
```

## Contributing
Contributions are welcome! Remember to write some tests for your changes.

Some tests rely on the existence of a tag file. If you change sample Java files
in `test/input/`, you'll need to regenerate a tag file. To do this, install
[Universal Ctags](https://github.com/universal-ctags/ctags) and run (from the
project root):
```
$ ctags -o test/input/tags -R --tag-relative=yes test/input
```

## License
This project is licensed under the MIT license.

