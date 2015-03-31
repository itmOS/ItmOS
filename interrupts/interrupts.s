section .text

global init_interrupts

INTERRUPTS_TABLE_SIZE   equ	1 << 11
IRQ_BASE                equ	0x20

%include "tty/tty.inc"

timer_int_handler:
        pusha
        popa
        iret
        
init_timer_int_handler:
        xchg bx, bx
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
        xchg bx, bx
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

;;; section .data
interrupt_table:
	times INTERRUPTS_TABLE_SIZE dd 0
.ptr:
        dw INTERRUPTS_TABLE_SIZE
        dd interrupt_table
