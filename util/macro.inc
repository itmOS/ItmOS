%ifndef UTIL_MACRO_INC
%define UTIL_MACRO_INC

%macro CCALL 1-*
	%rep (%0 - 1)
	%rotate -1
	push %1
	%endrep
	%rotate -1
	call %1
%endmacro

%endif
