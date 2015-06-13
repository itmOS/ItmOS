section .text

%include "util/macro.inc"
%include "dev/mem/mem_macro.inc"
%include "dev/mem/virtmem.inc"

extern get_physaddr
extern get_pages
extern put_pages
extern map_page
extern unmap_page

global sbrk


HEAP_BEGIN      equ     0xc0400000
HEAP_END        equ     0xFFFFDFFF
FLAG            equ     0x3

;;; Increases program break(end of data segment) with incr bytes
;;; int sbrk(int incr);
sbrk:
        mov eax, [esp + 4]
        push edi
        push esi
        push ecx
        push edx
        push ebx

        mov edi, eax
        ;; Check if first page of head is mapped
        CCALL get_physaddr, dword HEAP_BEGIN
        test eax, eax
        jnz .nomapping

        ;; Get physical page and map to it
	NEW_CLEAN_PHYSPAGE
        test eax, eax
        jz .fail

        mov ecx, eax
        CCALL map_page, dword HEAP_BEGIN, eax, dword FLAG
        test eax, eax
        jz .setbegin
        ;; If fail release physical page
        CCALL put_pages, ecx, dword 1
        jmp .fail
.setbegin:
        ;; Set brk structure, containing current length of not allocates memory
        mov dword [HEAP_BEGIN], 4
.nomapping:
        ;; Let edx be index of last mapped page
        mov dword edx, [HEAP_BEGIN]
        dec edx
        add edx, HEAP_BEGIN
        shr edx, 12
        ;; And ebx index last page that must be mapped
        mov dword ebx, edi
        dec ebx
	add dword ebx, [HEAP_BEGIN]
        add ebx, HEAP_BEGIN
        ;; Check if allocation is possible
        cmp ebx, HEAP_END
        jnl .fail

        shr ebx, 12
        
        ;; If page containing address to shift break to equal to last mapped update the break info
        cmp edx, ebx
        je .setexit
        ;; If last mapped page index is greater than destination page we need to free
        cmp edx, ebx
        jg .free
        ;; Otherwise make edx an iterator n pages to map
        inc edx
        mov esi, edx
.loop1:
        cmp edx, ebx
        jg .setexit

        ;; Get physical page to map
	NEW_CLEAN_PHYSPAGE
        ;; If fail we need to free already mapped pages
        test eax, eax
        jz .failfree
        mov ecx, eax
        ;; Map to edx index page physical address we got
        push edx
        sal dword edx, 12
        CCALL map_page, edx, eax, dword FLAG
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
        mov dword eax, [HEAP_BEGIN]
	add edi, eax
        add dword eax, HEAP_BEGIN
        ;; Set given address as current program break
        mov dword [HEAP_BEGIN], edi
.exit:
        pop ebx
        pop edx
        pop ecx
        pop esi
        pop edi
        ret
.fail:
        mov dword eax, -1
        jmp .exit
.failfree:
        cmp edx, esi
        je .fail
        CCALL unmap_page, esi
        inc esi
        jmp .failfree
