%ifndef INTERRUPTS_INC
%define INTERRUPTS_INC

INTERRUPTS_TABLE_SIZE           equ	1 << 11
INTERRUPT_HANDLERS_SIZE         equ	1 << 10

IRQ_BASE                        equ	0x20
IRQ_BASE2                       equ	0x28

PIC1_PORT1                      equ     0x20
PIC1_PORT2                      equ     0x21
PIC2_PORT1                      equ     0xA0
PIC2_PORT2                      equ     0xA1


;;; Sends 0x20 to PICs ports
%macro NOTIFYPIC 0
        mov al, 0x20
        out PIC1_PORT1, al
        out PIC2_PORT1, al
%endmacro

;;; Universal handler
;;; Saves registers, calls interrupt manager with interrupt number in eax, sends EOI
%macro INTHANDLER 1
        pusha
        mov eax, %1
        call interrupt_manager
        ;; Send EOI(end of interrupt) to PIC
        NOTIFYPIC
        popa
        iret
%endmacro

;;; Fills IDT element of given interrupt(2) using given handler(1), types and attributes(3)
%macro INITHANDLER 3 
        cli
        pusha
        jmp %%skip
        
%%handler:  
        INTHANDLER %2
%%skip:
        ;; Filling the IDT element
        mov eax, %%handler                              ; handler address
        mov ecx, %2                                     ; interrupt index

        ;; Saving handler to interrupt_handlers
        mov edx, %1
	mov dword ebx, [interrupt_handlers]
        mov [ebx + ecx * 4], dx
        shr edx, 16
        mov [ebx + ecx * 4 + 2], dx

	mov dword ebx, [interrupt_table]
        mov [ebx + ecx * 8], ax             ; set handler address 0..15 bits
        
        mov word [ebx + ecx * 8 + 2], 8     ; set code segment selector
        mov word [ebx + ecx * 8 + 4], %3    ; set type and attributes

        shr eax, 16                                      
        mov [ebx + ecx * 8 + 6], ax         ; set handler address 16..31 bits

        popa
        sti
%endmacro


;; Enables given bit on master PIC
%macro ENABLE_MASTER_BIT 1
        push eax
        mov al, %1
        or [MASTER_PIC_MASK], al
        mov al, [MASTER_PIC_MASK]
        not al
        out PIC1_PORT2, al
        pop eax
%endmacro


;; Disables given bit on master PIC
%macro DISABLE_MASTER_BIT 1
        push eax
        mov al, %1
        not al
        and [MASTER_PIC_MASK], al
        mov al, [MASTER_PIC_MASK]
        not al
        out PIC1_PORT2, al
        pop eax
%endmacro


;; Enables given bit on slave PIC
%macro ENABLE_SLAVE_BIT 1
        push eax
        mov al, %1
        or [SLAVE_PIC_MASK], al
        mov al, [SLAVE_PIC_MASK]
        not al
        out PIC2_PORT2, al
        pop eax
%endmacro


;; Disables given bit on slave PIC
%macro DISABLE_SLAVE_BIT 1
        push eax
        mov al, %1
        not al
        and [SLAVE_PIC_MASK], al
        mov al, [SLAVE_PIC_MASK]
        not al
        out PIC2_PORT2, al
        pop eax
%endmacro

%endif ; INTERRUPTS_INC
