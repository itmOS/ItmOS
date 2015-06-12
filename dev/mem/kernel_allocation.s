section .text

%include "util/macro.inc"

extern get_physaddr
extern get_pages
extern put_pages
extern map_page
extern unmap_page


begin_entry:
        dd 0

;;; void* kmalloc(int len)
;;; returns pointer to memory chunk of len bytes in kernel memory
kmalloc:
        ret

;;; void free(void* addr)
;;; frees memory chunk starting from addr in kernel memory
kfree:
        ret

HEAP_BEGIN      equ     0xc0400000


;;; Changes programs data break(end of data segment) to addr for kernel memory
;;; int kbrk(void* addr);
kbrk:
        mov eax, [esp + 4]
        push edi
        push ecx
        push edx
        push ebx

        ;; Check that brk to addr is possible
        cmp dword eax, HEAP_BEGIN
        jng .fail
        ;; At heap begin there is some kernel info, so adreess must be shifted
        cmp dword eax, 0xFFFFE000
        jnl .fail

        mov edi, eax
        ;; Check if first page of head is mapped
        CCALL get_physaddr, dword HEAP_BEGIN
        test eax, eax
        jnz .nomapping
        ;; Get physical page and map to it
        mov ecx, eax
        CCALL get_pages, dword 1
        test eax, eax
        jz .fail
        mov ecx, eax
        CCALL map_page, dword HEAP_BEGIN, eax, dword 0x3
        test eax, eax
        jnz .setbegin
        ;; If fail release physical page
        CCALL put_pages, ecx, dword 1
        jmp .fail
.setbegin:
        ;; Set brk structure, containing beginning of not allocates memory
        mov dword eax, HEAP_BEGIN
        add dword eax, 4
        mov dword [HEAP_BEGIN], eax
.nomapping:
        ;; Let edx be index of last mapped page
        mov dword edx, [HEAP_BEGIN]
        shl edx, 12
        ;; So if program break is begining if new page we must decrement edx
        mov ecx, edx
        sal dword ecx, 12
        cmp dword ecx, [HEAP_BEGIN]
        jl .continue
        dec edx
.continue:
        mov dword ebx, edi
        shl ebx, 12
        ;; If page containing address to shift break to equal to last mapped update the break info
        cmp edx, ebx
        je .setexit
        ;; If last mapped page index is greater than destination page we need to free
        cmp edx, ebx
        jg .free
        ;; Otherwise make edx an iterator n pages to map
        inc edx
        mov ecx, edx
.loop1:
        cmp edx, ebx
        jg .setexit

        ;; Get physical page to map
        CCALL get_pages, dword 1
        ;; If fail we need to free already mapped pages
        test eax, eax
        jz .failfree
        ;; Map to edx index page physical address we got
        push edx
        sal dword edx, 12
        CCALL map_page, edx, eax, dword 0x7
        mov ecx, eax
        pop edx
        ;; If fail we need to free already mapped pages and free current physical page
        test eax, eax
        jnz .finishloop1
        CCALL put_pages, ecx, dword 1
        jmp .failfree
.finishloop1:
        inc edx
        jmp .loop1
.free:
        ;; Here edx points to last mapped page
        cmp edx, ebx
        je .setexit
        CCALL unmap_page, edx
        dec edx
        jmp .free
.setexit:
        ;; Set given address as current program break
        mov dword [HEAP_BEGIN], edi
.exit:
        pop ebx
        pop edx
        pop ecx
        pop edi
        xor eax, eax
        ret
.fail:
        mov dword eax, -1
        jmp .exit
.failfree:
        cmp edx, ecx
        je .fail
        CCALL unmap_page, ecx
        inc ecx
        jmp .failfree
