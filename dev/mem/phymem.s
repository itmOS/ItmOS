
%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"

extern window
extern begin_page
extern map_to_window

global get_pages
global put_pages

section .text
KERNEL_PHY              equ 0x400000
PAGE_SIZE               equ 0x1000
PAGE_SIZE_OFFSET        equ 12
WINDOW                  equ 0xFFFFF000
WINDOW_PAGE_NUMBER      equ 1023
DEFAULT_ACCESS_MODE     equ 0x7

%macro SAFE_WINDOW 1
        push eax
        CCALL map_to_window, %1
        pop eax
%endmacro


;;; Takes amount of pages and return address of memory block if given size
;;; Returns 0 if amount of free memory is less
;;; Return 0 if there is no coherent block of input size
;;; If memory needed can be divided use get_one_page
get_pages:
        mov dword eax, [esp + 4]        ; get size

        push edi
        push esi
        push ebx
        push edx
        push ecx

        mov dword edx, 0x100000         ; set size to maximum
        xor edi, edi                    ; answer block
        xor esi, esi                    ; previous of answer block
        xor ebx, ebx                    ; previous
        mov dword ecx, [begin_page]     ; current block
.loop:
        ;; check if loop finishing
        test ecx, ecx
        jz .exitloop
        ;; Map beginning of current block
        SAFE_WINDOW ecx
        ;; Compare current size with needed amount
        cmp dword [WINDOW], eax
        jl .finishloop
        ;; Compare current size with current answer
        cmp [WINDOW], edx
        jge .finishloop
        ;; Set answer
        mov edx, [WINDOW]
        mov edi, ecx
        mov esi, ebx
.finishloop:
        ;; Mov current block ti previous, next of current to current
        mov ebx, ecx
        mov dword ecx, [WINDOW + 4]
        jmp .loop
.exitloop:
        test edi, edi
        jz .fail
        ;; Map answer to window

        SAFE_WINDOW edi
        ;; Check if we need to remove whole block
        cmp edx, eax
        je .remove
        ;; Decrease size of block
        sub [WINDOW], eax
        ;; Get length in bytes
        mov eax, [WINDOW]
        shl dword eax, 12
        ;; Get pointer to allocated memory
        add eax, edi
        jmp .exit
.remove:
        mov dword ecx, [WINDOW + 4]
        ;; Check if remove the first block
        test esi, esi
        jz .notfirst
        ;; Set next of answer as beginning
        mov [begin_page], ecx
        mov eax, edi
        jmp .exit
.notfirst:
        SAFE_WINDOW esi
        ;; Set next of previous of answer to next of answer
        mov [WINDOW + 4], ecx
        mov eax, edi
.exit:
        pop ecx
        pop edx
        pop ebx
        pop esi
        pop edi
        ret
.fail:
        xor eax, eax
        jmp .exit
;;; Takes address and amount of pages of memory block and frees pages
put_pages:
        mov dword ecx, [esp + 4]        ; get left bound of block to add
        mov dword ebx, [esp + 8]
        
        pusha
        mov esi, ebx                    ; save size
        sal dword ebx, 12
        add ebx, ecx                    ; get right bound of block to add
        mov dword eax, [begin_page]     ; current block
        xor edx, edx                    ; previous of current block
.loop:
        test eax, eax
        jz .exitloop
        ;; Map current block
        SAFE_WINDOW eax
        ;; Get its right bound
        mov dword edi, [WINDOW]
        sal dword edi, 12
        add edi, eax

        ;; Check if current block is on the left or on the right
        cmp ecx, eax
        jnl .rightbound

        ;; Check if current blocks left bound equal to right bound of block to add
        cmp ebx, eax
        je .eqrightbound
        ;; Just add new block and set its next to current
        SAFE_WINDOW ecx
        ;; Put size
        mov [WINDOW], esi
        ;; Put current block as next
        mov [WINDOW + 4], eax

        jmp .exit_with_prev
.eqrightbound:   
        ;; Get size and next of current page
        mov dword edi, [WINDOW]
        mov dword ebx, [WINDOW + 4]
        SAFE_WINDOW ecx
        ;; Just add page with sum of sizes of current and to add and current's next
        mov [WINDOW], esi
        add dword [WINDOW], edi
        mov [WINDOW + 4], ebx

        jmp .exit_with_prev
.rightbound:
        ;; If currents left bound is not equal to left bound of block to add
        ;; Can do nothing so continue
        cmp ecx, edi
        jne .finishloop
        ;; Otherwise add size of block to add to current(it is mapped to window already)
        add dword [WINDOW], esi
        mov dword edx, [WINDOW + 4]
        ;; Check if there is next
        test edx, edx
        ;; If not nothing to do - exit
        jz .exit
        ;; Fet right bound of new block
        sal dword ebx, 12
        add ebx, eax
        ;; Check if its beginning is equal to new current blocks end
        cmp edx, ebx
        jne .exit
        SAFE_WINDOW edx
        ;; Get next's size
        mov dword ecx, [WINDOW]
        ;; Get next's next
        mov dword edi, [WINDOW + 4]
        SAFE_WINDOW eax
        ;; Add next's size to current block
        add dword [WINDOW], ecx
        ;; Replace current's next with next's next
        mov dword [WINDOW + 4], edi
        jmp .exit
.finishloop:
        SAFE_WINDOW eax
        ;; Set current to previous
        mov edx, eax
        ;; Set current next to current
        mov dword eax, [WINDOW + 4]
        jmp .loop
.exitloop:
        ;; If we are here, block to add is after the last block
        ;; Or there are no blocks
        SAFE_WINDOW ecx
        ;; Just add new block with no next
        mov dword [WINDOW], esi
        mov dword [WINDOW + 4], 0

        jmp .exit_with_prev
.exit:
        popa
        ret
.exit_with_prev:
        ;; Check if has previous
        test edx, edx
        jnz .set_prev
        ;; If not set begin page to point to block to add
        mov dword [begin_page], ecx
        jmp .exit
.set_prev:
        ;; Map previous and set next to block to add
        SAFE_WINDOW edx
        mov [WINDOW + 4], ecx
        jmp .exit
