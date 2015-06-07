section .text

%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"

extern window
extern begin_page
extern map_to_window

KERNEL_PHY              equ 0x400000
PAGE_SIZE               equ 0x1000
PAGE_SIZE_OFFSET        equ 12
WINDOW                  equ 0xFFFFF000
WINDOW_PAGE_NUMBER      equ 1023
DEFAULT_ACCESS_MODE     equ 0x7


;;; Takes amount of pages and return address of memory block if given size
;;; Returns 0 if amount of free memory is less
;;; Return 0 if there is no coherent block of input size
;;; If memory needed can be divided use get_one_page
get_pages:
        pusha
        mov dword eax, [esp + 4]        ; get size
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
        CCALL map_to_window, ecx
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
        CCALL map_to_window, edi
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
        CCALL map_to_window, esi
        ;; Set next of previous of answer to next of answer
        mov [WINDOW + 4], ecx
        mov eax, edi
.exit:
        popa
        ret
.fail:
        xor eax, eax
        popa
        ret



;;; Takes amount of pages and return address of memory block if given size
;;; Returns -1 if amount of free memory is less
;;; Return -1 if there is no coherent block of input size
;;; If memory needed can be divided use get_one_page
get_pages:
        ret
