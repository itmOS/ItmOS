section .text

%include "tty/tty.inc"
%include "ata/ata.inc"

global kernel_main

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	ATA_PIO_OUTBYTE [mem], 1
	xor eax, eax
	ATA_PIO_INBYTE [mem]
	TTY_PUTC al
	hlt
	jmp $

section .data
hello_world: db 'Hello, world!', 0
mem: dd 200
zero: dd 0

section .bss
stack:
        resd 0x1000
stack_top:
