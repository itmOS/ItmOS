section .text

extern init_interrupts

%include "tty/tty.inc"
%include "ata/ata.inc"

global kernel_main

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	call init_interrupts
	mov [memout + 0], byte 's'
	mov [memout + 1], byte 'u'
	mov [memout + 2], byte 'c'
	mov [memout + 3], byte 'c'
	mov [memout + 4], byte 'e'
	mov [memout + 5], byte 's'
	mov [memout + 6], byte 's'
	mov [memout + 7], byte 10
	mov [memout + 8], byte 0
	mov [memout + 300], byte 'y'
	mov [memout + 301], byte 'e'
	mov [memout + 302], byte 's'
	mov [memout + 303], byte 10
	mov [memout + 304], byte 0
	ATA_PIO_OUTSEG [lba], memout, 2
	ATA_PIO_INSEG [lba], memin, 2
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), memin
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), memin + 300
	jmp $

section .data
hello_world: db 'Hello, world!', 0
memin: times 600 dw 0
memout: times 600 dw 0
lba: dd 200

section .bss
stack:
        resd 0x1000
stack_top:
