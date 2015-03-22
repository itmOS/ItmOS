section .text

global kernel_main

;;; Entry point of the kernel.
kernel_main:
        mov dword [0xB8000], 'h e '
	hlt
	jmp $
