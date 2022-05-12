" Search the tagfiles for a tag exactly matching the given keyword.
" Returns a list of results, structured as follows:
"
" [{ 'type': <c,e,i,g,a,m>, 's': v:true/v:false, 'fq_name': [...], 'fname': '...'}, ...]
"
" May return an empty list if tags could not be read, or if none of the files
" have a package statement.
function! java_support#tags#Lookup(keyword) abort
	" match keywords against tagfiles, looking for classes
	let l:prompt_results = []

	" read tags for keyword and filter for classes
	let l:tags = taglist('^\C' . a:keyword . '$')
	for tag in l:tags
		if !has_key(tag, 'filename') || !has_key(tag, 'kind') || !has_key(tag, 'name')
			continue
		endif

		let l:package = s:FindPackageForFile(tag.filename)
		if empty(l:package)
			continue
		endif

		if tag.kind == 'c' || tag.kind == 'i' || tag.kind == 'g' || tag.kind == 'a'
			if has_key(tag, 'class')
				let l:fq_name = java_support#util#Flatten([l:package, tag.class, tag.name])
			else
				let l:fq_name = java_support#util#Flatten([l:package, tag.name])
			endif

			call add(l:prompt_results, {
				\ 'fname': tag.filename,
				\ 'type': tag.kind,
				\ 's': v:false,
				\ 'fq_name': l:fq_name
				\ })
		elseif tag.kind == 'm'
			if !has_key(tag, 'class')
				continue
			endif

			call add(l:prompt_results, {
				\ 'fname': tag.filename,
				\ 'type': tag.kind,
				\ 's': v:true,
				\ 'fq_name': java_support#util#Flatten([l:package, tag.class, tag.name])
				\ })
		elseif tag.kind == 'e'
			if !has_key(tag, 'enum')
				continue
			endif

			call add(l:prompt_results, {
				\ 'fname': tag.filename,
				\ 'type': tag.kind,
				\ 's': v:true,
				\ 'fq_name': java_support#util#Flatten([l:package, tag.enum, tag.name])
				\ })
		endif
	endfor

	return l:prompt_results
endfunction

" Read the contents of `file` and look for a package statement.
"
" Loading the entire file into memory can be pretty wasteful, given that
" package statements usually appear very close to the top of the file. To
" reduce overhead, files are read incrementally. In the worst case, this could
" result in multiple file reads, but in the normal case will improve overall
" performance.
"
" If found, returns the package statement components. Otherwise returns an
" empty list.
function! s:FindPackageForFile(file) abort
	let l:chunk = 10
	let l:offset = 0

	while v:true
		let l:lines = readfile(a:file, '', l:chunk)

		for line in l:lines[l:offset:-1]
			let l:matches = matchlist(line, 'package\s\+\([^;]\+\);')

			if !empty(l:matches)
				return split(substitute(l:matches[1], '\s', '', 'g'), '\.')
			endif
		endfor

		" if we have reached end of file
		if len(l:lines) < l:chunk
			return []
		endif

		let l:offset = len(l:lines)
		let l:chunk *= 3
	endwhile

	return []
endfunction

