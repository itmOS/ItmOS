section .text

global init_interrupts

INTERRUPTS_TABLE_SIZE   equ	1 << 11
IRQ_BASE                equ	0x20

%include "tty/tty.inc"

%macro putToPIC 1
        mov al, %1
        out 0x20, al
        out 0xA0, al
%endmacro

%macro wrapHandler 2
        pusha

        call %1
        putToPIC %2

        popa
        iret
%endmacro


timer_int_handler:
        wrapHandler timer_int, 0x20

timer_int:
	xchg bx, bx

	;; Set some good color
	mov ax, 'oo'
	;; Load cool symbol
	mov al, [timer_symbol]
	;; Print it
	mov [0xB8000], ax

	;; Change this cool symbol for the next time
	sub al, 'a'
	xor al, 1
	add al, 'a'
	;; And save it
	mov [timer_symbol], al
        ret



init_timer_int_handler:
        pusha

        mov eax, timer_int_handler
        mov [interrupt_table + IRQ_BASE * 8], ax
        mov word [interrupt_table + IRQ_BASE * 8 + 2], 8
        mov word [interrupt_table + IRQ_BASE * 8 + 4], 0x8E00
        shr eax, 16
        mov [interrupt_table + IRQ_BASE * 8 + 6], ax

        popa
        ret

init_interrupts:
        push eax
	lidt [interrupt_table.ptr]
        
        mov al, 0x11
        out 0x20, al
        out 0xA0, al
        
        mov al, 0x20
        out 0x21, al

        mov al, 0x28
        out 0xA1, al

        mov al, 0x04
        out 0x21, al

        mov al, 0x02
        out 0xA1, al

        mov al, 0x01
        out 0x21, al

        mov al, 0x01
        out 0xA1, al

        mov al, 0x0
        out 0x21, al

        mov al, 0x0
        out 0xA1, al

        call init_timer_int_handler
        pop eax
        sti
	ret

section .data
interrupt_table:
	times INTERRUPTS_TABLE_SIZE dd 0
.ptr:
        dw INTERRUPTS_TABLE_SIZE
        dd interrupt_table

timer_symbol:	db 'a'
