%ifndef UTIL_MACRO_INC
%define UTIL_MACRO_INC

%macro CCALL 1-*
    push edx
	%rep (%0 - 1)
	%rotate -1
    mov edx, %1
	push edx
	%endrep
	%rotate -1
	call %1
    %rep (%0 - 1)
    add esp, 4
    %endrep
    pop edx
%endmacro

%endif
