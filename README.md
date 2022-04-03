# java-sort-imports.vim
A Vim plugin that rearranges import statements in Java files.

## Installation
This plugin has no external dependencies, so you can easily install with your
favourite plugin manager.

With [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'brandon1024/java-sort-imports.vim'
```

## Usage
To sort import statements in the current buffer:
```
:JavaSortImports
```

You can add a mapping to make your life a bit easier:
```vim
nnoremap <silent> <leader>o :JavaSortImports<CR>
```

If you're feeling bold, automatically sort imports before writing the buffer:
```vim
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
```vim
let g:java_import_order = [
	\ { 'static': 1, 'packages': [] },
	\ { 'static': 0, 'packages': ['java.', 'javax.'] },
	\ { 'static': 0, 'packages': [] }]
```

### `g:java_import_space_group`
Insert an empty line between import groups.

Default:
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
import java.util.Collections;
import java.util.List;

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

## License
This project is licensed under the MIT license.

