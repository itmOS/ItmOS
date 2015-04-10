section .text

global init_interrupts

INTERRUPTS_TABLE_SIZE           equ	1 << 11
IRQ_BASE                        equ	0x20
IRQ_BASE2                       equ	0x28

MASTER_PIC_MASK                 equ     0x03
SLAVE_PIC_MASK                  equ     0x00

PIC1_PORT1                      equ     0x20
PIC1_PORT2                      equ     0x21
PIC2_PORT1                      equ     0xA0
PIC2_PORT2                      equ     0xA1

%include "tty/tty.inc"

;;; Sends 0x20 to PICs ports
%macro NOTIFYPIC 0
        mov al, 0x20
        out PIC1_PORT1, al
        out PIC2_PORT1, al
%endmacro

;;; Universal wrapper for handlers
;;; Saves registers, calls handler, sends EOI
%macro WRAPHANDLER 1
        pusha

        call %1
        ;; Send EOI(end of interrupt) to PIC
        NOTIFYPIC

        popa
        iret
%endmacro

;;; Fills IDT element of given interrupt(2) using given handler(1), types and attributes(3)
%macro INITHANDLER 3 
        pusha
        ;; Filling the IDT element
        mov eax, %1                                     ; handler address
        mov ecx, %2                                     ; interrupt index
        
        mov [interrupt_table + ecx * 8], ax             ; set handler address 0..15 bits
        mov word [interrupt_table + ecx * 8 + 2], 8     ; set code segment selector
        mov word [interrupt_table + ecx * 8 + 4], %3    ; set type and attributes
        shr eax, 16                                      
        mov [interrupt_table + ecx * 8 + 6], ax         ; set handler address 16..31 bits

        popa
%endmacro

timer_int_handler:
        WRAPHANDLER timer_int

keyboard_int_handler:
        WRAPHANDLER keyboard_int

keyboard_int:
	xchg bx, bx
        ;; TODO process scan-code to ASCII-code
        ;; Shows some symbol
	mov ax, 'oo'
        in al, 0x60
	;; TODO: Hardcoded place?
	mov [0xB8000 + 2*80*25 - 2], ax
        ret

timer_int:
	xchg bx, bx

	;; Set some good color
	mov ax, 'oo'
	;; Load cool symbol
	mov al, [timer_symbol]
	;; Print it
	;; TODO: Hardcoded place?
	mov [0xB8000 + 2 * 80*25 - 4], ax

	;; Change this cool symbol for the next time
	sub al, 'a'
	xor al, 1
	add al, 'a'
	;; And save it
	mov [timer_symbol], al
        ret

init_interrupts:
        push eax
        ;; Set IDT address 
	lidt [interrupt_table.ptr]

        ;; remap the PICs beyond 0x20
        ;; 0x20  because Intel have designated the first 32 interrupts as "reserved" for cpu exceptions
        
        ;; Start initialising sequence
        mov al, 0x11
        out PIC1_PORT1, al
        out PIC2_PORT1, al

        ;; Send to PIC1 new start of interrupts
        mov al, IRQ_BASE
        out PIC1_PORT2, al
        ;; Send to PIC2 new start of interrupts
        mov al, IRQ_BASE2
        out PIC2_PORT2, al
        ;; Set PIC1 as master
        mov al, 0x04
        out PIC1_PORT2, al
        ;; Set PIC2 as slave
        mov al, 0x02
        out PIC2_PORT2, al
        ;; Set 8086 mode for PIC1 and PIC2
        mov al, 0x01
        out PIC1_PORT2, al
        mov al, 0x01
        out PIC2_PORT2, al
        
        ;; Disable all IRQ for PIC2, PIC1
        ;; Enable keyboard, timer for PIC1
        mov al, ~MASTER_PIC_MASK
        out PIC1_PORT2, al
        mov al, ~SLAVE_PIC_MASK
        out PIC2_PORT2, al

        ;; Set handler for timer interrupts
        INITHANDLER timer_int_handler, IRQ_BASE, 0x8E00
        ;; Set handler for keyboard interrupts
        INITHANDLER keyboard_int_handler, IRQ_BASE + 1, 0x8E00

        pop eax
        ;; Enable interrupts
        sti
	ret

section .data
interrupt_table:
	times INTERRUPTS_TABLE_SIZE dd 0
.ptr:
        dw INTERRUPTS_TABLE_SIZE
        dd interrupt_table

timer_symbol:	db 'a'
