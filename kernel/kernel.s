section .text

%include "tty/tty.inc"

global kernel_main

;;; Entry point of the kernel.
kernel_main:
        TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), hello_world
	hlt
	jmp $

section .data
hello_world: db 'Hello, world!', 0
