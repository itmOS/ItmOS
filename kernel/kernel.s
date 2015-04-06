section .text

%include "tty/tty.inc"
%include "ata/ata.inc"

global kernel_main

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	mov byte al, 1
	push eax
	mov byte al, 2
	TTY_PUTC al
	pop eax
	TTY_PUTC al
	ATA_PIO_OUTBYTE [ten], [zero], 1
	xor al, al
	ATA_PIO_INBYTE [ten], [zero]
	TTY_PUTC al
	hlt
	jmp $

section .data
hello_world: db 'Hello, world!', 0
ten: dw 0
zero: dd 0

section .bss
stack:
        resd 0x1000
stack_top:
