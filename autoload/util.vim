" Return true if `ident` is a valid Java identifier (package) component.
function! util#IsValidJavaIdentifierComponent(ident)
	if !len(a:ident)
		return v:false
	endif

	" See Java SE Spec, section 3.8
	return match(a:ident, '^[a-zA-Z$_][a-zA-Z0-9$_]*$') >= 0
endfunction

