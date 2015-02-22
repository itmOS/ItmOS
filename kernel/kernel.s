section .text

global kernel_main

;;; Entry point of the kernel.
kernel_main:
	hlt
	jmp $
