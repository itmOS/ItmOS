section .text

%include "tty/tty.inc"
%include "ata/ata.inc"

global kernel_main

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	mov byte al, 1
	;push eax
	;mov byte al, 2
	;TTY_PUTC al
	;pop eax
	;TTY_PUTC al
  ;      TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), hello_world
	ATA_PIO_OUTBYTE 100, 1
	ATA_PIO_INBYTE 100
	hlt
	jmp $

section .data
hello_world: db 'Hello, world!', 0

section .bss
stack:
        resd 0x1000
stack_top:
