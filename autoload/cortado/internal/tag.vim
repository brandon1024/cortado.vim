" Create a new tag handle.
function! cortado#internal#tag#new() abort
	let l:handle = {}

	let l:handle.lookup = function('s:lookup')

	return l:handle
endfunction

" Search the tagfiles for a tag exactly matching the given keyword.
" Returns a list of results, structured as follows:
"
" [{ 'type': <c,e,i,g,a,m>, 's': v:true/v:false, 'fq_name': [...], 'fname': '...'}, ...]
"
" May return an empty list if tags could not be read, or if none of the files
" have a package statement.
function! s:lookup(keyword) abort
	let l:utils = cortado#internal#util#new()

	let l:prompt_results = []
	for [tag, package] in s:tags_matching_keyword(a:keyword)
		if index(['c', 'i', 'g', 'a'], tag.kind) >= 0
			call extend(l:prompt_results, s:class(tag, package))
		elseif tag.kind == 'm'
			call extend(l:prompt_results, s:method(tag, package))
		elseif tag.kind == 'e'
			call extend(l:prompt_results, s:enum(tag, package))
		endif
	endfor

	return l:prompt_results
endfunction

" Find all tags matching a keyword, returning the tag and the package for
" each result.
function! s:tags_matching_keyword(keyword) abort
	let l:java = cortado#internal#java#new()

	return taglist('^\C' . a:keyword . '$')
		\ ->filter({ _, tag -> !s:is_tainted(tag) })
		\ ->map({ _, tag -> [tag, l:java.get_package_for_file(tag.filename)] })
		\ ->filter({ _, result -> !empty(result[1]) })
endfunction

" Check if a tag match is unusable (missing fields, file not readable).
function! s:is_tainted(tag) abort
	if !has_key(a:tag, 'filename') || !has_key(a:tag, 'kind') || !has_key(a:tag, 'name')
		return v:true
	endif

	if !filereadable(a:tag.filename)
		return v:true
	endif

	return v:false
endfunction

function! s:enum(tag, package) abort
	let l:utils = cortado#internal#util#new()

	if !has_key(a:tag, 'enum')
		return []
	endif

	return [{
		\ 'fname': a:tag.filename,
		\ 'type': a:tag.kind,
		\ 's': v:true,
		\ 'fq_name': l:utils.flatten([a:package, a:tag.enum, a:tag.name])
	\ }]
endfunction

function! s:method(tag, package) abort
	let l:utils = cortado#internal#util#new()

	if !has_key(a:tag, 'class')
		return []
	endif

	return [{
		\ 'fname': a:tag.filename,
		\ 'type': a:tag.kind,
		\ 's': v:true,
		\ 'fq_name': l:utils.flatten([a:package, a:tag.class, a:tag.name])
	\ }]
endfunction

function! s:class(tag, package) abort
	let l:utils = cortado#internal#util#new()

	if has_key(a:tag, 'class')
		let l:fq_name = l:utils.flatten([a:package, a:tag.class, a:tag.name])
	else
		let l:fq_name = l:utils.flatten([a:package, a:tag.name])
	endif

	return [{
		\ 'fname': a:tag.filename,
		\ 'type': a:tag.kind,
		\ 's': v:false,
		\ 'fq_name': l:fq_name
	\ }]
endfunction

