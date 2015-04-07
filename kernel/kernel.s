section .text

%include "tty/tty.inc"
%include "ata/ata.inc"

global kernel_main

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	mov [memout], byte 's'
	mov [memout + 1], byte 'u'
	mov [memout + 2], byte 'c'
	mov [memout + 3], byte 'c'
	mov [memout + 4], byte 'e'
	mov [memout + 5], byte 's'
	mov [memout + 6], byte 's'
	mov [memout + 7], byte 10
	mov [memout + 8], byte 0
	ATA_PIO_OUTSEG [lba], memout
	ATA_PIO_INSEG [lba], memin
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), memin
	hlt
	jmp $

section .data
hello_world: db 'Hello, world!', 0
memin: times 300 dw 0
memout: times 300 dw 0
lba: dd 200

section .bss
stack:
        resd 0x1000
stack_top:
