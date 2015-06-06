%ifndef DEV_KBD_INC
%define DEV_KBD_INC

extern get_from_scancode
extern buf_getc
extern buf_putc
extern buf_delc

;; Adds char to buffer
%macro KBDBUF_PUTC 1
	pusha
	mov byte al, %1
	call buf_putc
	popa
%endmacro

%macro KBDBUF_GETC 0
	call buf_getc
%endmacro

%macro KBDBUF_DELC 0
	call buf_delc
%endmacro

%endif
