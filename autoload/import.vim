" - search (and cache) imports in other project files
" - omit import if the import is in the same package (stretch goal?)
" - nested classes and enums (kinda difficult)
" - compound statements (will take some regex magic)
" - restore buffer if there's an error (will take a bit of work)

" Get the keyword (<cword>) under the cursor.
function! s:GetKeywordUnderCursor() abort
	return expand('<cword>')
endfunction

" Filter a list of `tags` and return only those that have a 'kind' `kind`.
function! s:FilterTagsByKind(tags, kind) abort
	let l:result = []
	for tag in a:tags
		if has_key(tag, 'kind') && tag.kind == a:kind
			call add(l:result, tag)
		endif
	endfor

	return l:result
endfunction

" Filter a list of `tags` and return only those that have a 'kind' of 'c'
" (class).
function! s:FilterTagClasses(tags) abort
	return s:FilterTagsByKind(a:tags, 'c')
endfunction

" Filter a list of `tags` and return only those that have a 'kind' of 'e'
" (enum).
function! s:FilterTagEnums(tags) abort
	return s:FilterTagsByKind(a:tags, 'e')
endfunction

" Read tag files for classes and enums with a name matching the given keyword.
" Return a list of class references with the following format:
" 	[{ 'type': '<c or e>', 'fq_classname': 'com.example.Keyword', filename: '<filename>' }, ...]
"
" May return an empty list if tags could not be read, or if none of the files
" have a package statement.
function! s:ReadTagsForImports(keyword) abort
	" match keywords against tagfiles, looking for classes
	let l:prompt_results = []

	" read tags for keyword and filter for classes
	let l:tags = taglist('^' . a:keyword . '$')
	let l:tags = s:FilterTagClasses(l:tags) + s:FilterTagEnums(l:tags)

	" for each result, read the file and look for a package statement
	for tag in l:tags
		for line in readfile(tag.filename)
			let l:matches = matchlist(line, 'package\s\+\([^;]\+\);')

			if len(l:matches)
				let l:fq_classname = l:matches[1] . '.' . a:keyword

				" if this tag is an enum, we'll build it a bit different
				if tag.kind == 'e' && has_key(tag, 'enum')
					let l:fq_classname = l:matches[1] . '.' . tag.enum . '.' . a:keyword
				endif

				call add(l:prompt_results, {
					\ 'type': tag.kind,
					\ 'fq_classname': l:fq_classname,
					\ 'filename': tag.filename
					\ })
				break
			endif
		endfor
	endfor

	" if we none of the files have a package statement, return
	if !len(l:prompt_results)
		return []
	endif

	return l:prompt_results
endfunction

" Callback for the popup menu.

" Show a popup menu with the possible classes or enums to import, allowing the
" user to select which to import.
function! s:ImportFromSelection(keyword, import_tag_results) abort
	let l:popup_entries = []
	for result in a:import_tag_results
		call add(l:popup_entries, ' ' . result.fq_classname . ' [' . result.type . '] ')
	endfor

	function! s:PopupMenuCallback(id, result) abort closure
		if a:result <= 0
			return
		endif

		if a:result > len(a:import_tag_results)
			echoerr 'bug: unexpected result in popup callback "' . a:result. '"'
		endif

		let l:path = a:import_tag_results[a:result - 1].fq_classname
		call s:ImportClass(l:path)
	endfunction

	call popup_create(l:popup_entries, {
		\ 'line': 'cursor+1',
		\ 'col': 'cursor',
		\ 'title': '  import "' . a:keyword . '"?',
		\ 'wrap': v:false,
		\ 'moved': 'word',
		\ 'cursorline': 1,
		\ 'filter': function('popup_filter_menu'),
		\ 'callback': function('s:PopupMenuCallback')
		\ })
endfunction

" Import a class with the given fully-qualified class name.
function! s:ImportClass(fq_classname) abort
	let l:trees = import_tree#Build()
	call import_tree#Merge(l:trees, a:fq_classname)
	call sort#JavaSortImportsTrees(l:trees)

	echo 'imported "' . a:fq_classname . '"'
endfunction

" Import a class with name `keyword`. If `keyword` is empty or unset, default
" to keyword under cursor (<cword>).
" If a keyword is provided as a function argument, the first result is
" imported. Otherwise, a popup menu is shown allowing the user to select which
" class to import.
function! import#JavaImportKeyword(keyword = '') abort
	" ensure this is a java file
	if &filetype != 'java'
		echohl WarningMsg |
			\ echo 'cannot import class: unexpected filetype "' . &filetype . '"' |
			\ echohl None
		return
	endif

	if !len(tagfiles())
		echohl WarningMsg |
			\ echo 'cannot import class: missing a tag file' |
			\ echohl None
		return
	endif

	let l:keyword = a:keyword ? a:keyword : s:GetKeywordUnderCursor()
	if l:keyword == ''
		return
	endif

	" make sure the keyword is a valid java identifier
	if !util#IsValidJavaIdentifierComponent(l:keyword)
		echohl WarningMsg |
			\ echo 'keyword "' . keyword . '" is not a valid Java identifier' |
			\ echohl None
		return
	endif

	let l:import_tag_results = s:ReadTagsForImports(l:keyword)
	if !len(l:import_tag_results)
		echohl WarningMsg |
			\ echo 'cannot import class: no classes found for keyword "' . a:keyword . '"' |
			\ echohl None
		return
	endif

	call s:ImportFromSelection(l:keyword, l:import_tag_results)
endfunction

