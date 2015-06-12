section .text

%include "tty/tty.inc"
%include "dev/kbd/kbd.inc"
%include "dev/mem/mem_macro.inc"
%include "interrupts_macro.inc"
%include "util/macro.inc"

global init_interrupts
global interrupt_manager
global interrupt_handlers

global MASTER_PIC_MASK
global SLAVE_PIC_MASK

extern malloc

;;; Gets number of interrupt in eax and calls handler for it
interrupt_manager:
        mov dword ebx, [interrupt_handlers]
        mov dword eax, [ebx + eax * 4]
        call eax
        ret

;;; Handler for keyboard
;;; Todo SHIFT support
keyboard_int:
        xor eax, eax
        in al, 0x60
        push eax
        call get_from_scancode
        add esp, 4
        test al, al
        jz .exit

	TTY_PUTC al
.exit:
        ret

;;; Useless handler for timer interrupts
timer_int:
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
        push edi

        CCALL malloc, INTERRUPT_HANDLERS_SIZE
        mov dword [interrupt_handlers], eax 

        CCALL malloc, INTERRUPTS_TABLE_SIZE
        mov dword [interrupt_table], eax 
        CLEAR eax, dword INTERRUPTS_TABLE_SIZE
        mov edi, eax

        CCALL malloc, dword 6
        mov word [eax], INTERRUPTS_TABLE_SIZE
        mov dword [eax + 2], edi
        
        ;; Set IDT address 
	lidt [eax]

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

        ;; Disable all for both master and slave PICs
        mov al, 0x00
        not al
        out PIC1_PORT2, al
        out PIC2_PORT2, al

        ;; Set handler for timer interrupts and enable them
        ENABLE_MASTER_BIT 0x01
        INITHANDLER timer_int, IRQ_BASE, 0x8E00
        ;; Set handler for keyboard interrupts and enable them
        ENABLE_MASTER_BIT 0x02
        INITHANDLER keyboard_int, IRQ_BASE + 1, 0x8E00

        pop edi
        pop eax
        ;; Enable interrupts
        sti
	ret

section .data
interrupt_table:
                        dd 0
interrupt_handlers:
                        dd 0

timer_symbol:	        db      'a'
MASTER_PIC_MASK:        db     0x00
SLAVE_PIC_MASK:         db     0x00
