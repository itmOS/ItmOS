section .text

global init_interrupts

INTERRUPTS_NUMBER	equ	1 << 11


init_interrupts:
	lidt [interrupt_table]

	sti
	iret

section .data
interrupt_table:
	times INTERRUPTS_NUMBER dd 0
