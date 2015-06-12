section .text

%include "tty/tty.inc"
%include "dev/kbd/kbd.inc"
%include "interrupts_macro.inc"
%include "boot/boot.inc"

global init_interrupts
global interrupt_manager
global interrupt_handlers

global MASTER_PIC_MASK
global SLAVE_PIC_MASK

;;; Gets number of interrupt in eax and calls handler for it
interrupt_manager:
        ;; TODO Maybe the following could be done
        ;; in a more clever way?..
        mov cx, ds
        shl ecx, 16
        mov cx, es
        push ecx
        mov cx, fs
        shl ecx, 16
        mov cx, gs
        push ecx
        mov cx, PRIVILEGED_DATA
        mov ds, cx
        mov es, cx
        mov fs, cx
        mov gs, cx
        call dword [interrupt_handlers + eax * 4]
        pop ecx
        mov gs, cx
        shr ecx, 16
        mov fs, cx
        pop ecx
        mov es, cx
        shr ecx, 16
        mov ds, cx
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
        
        mov dword ecx, 8
        cmp al, cl
        je .backspace
        KBDBUF_PUTC al
	TTY_PUTC al
        jmp .exit
.backspace:
	TTY_DELC
        KBDBUF_DELC
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

        ;; Disable all for both master and slave PICs
        mov al, 0x00
        not al
        out PIC1_PORT2, al
        out PIC2_PORT2, al

        ;; Set handler for timer interrupts and enable them
        ENABLE_MASTER_BIT 0x01
        IRQINITHANDLER timer_int, IRQ_BASE, 0x8E00
        ;; Set handler for keyboard interrupts and enable them
        ENABLE_MASTER_BIT 0x02
        IRQINITHANDLER keyboard_int, IRQ_BASE + 1, 0x8E00

        pop eax
        ;; Enable interrupts
        sti
	ret

section .data
interrupt_table:
	times INTERRUPTS_TABLE_SIZE db 0
.ptr:
        dw INTERRUPTS_TABLE_SIZE
        dd interrupt_table

interrupt_handlers:
	times INTERRUPT_HANDLERS_SIZE db 0

timer_symbol:	        db      'a'
MASTER_PIC_MASK:        db     0x00
SLAVE_PIC_MASK:         db     0x00
