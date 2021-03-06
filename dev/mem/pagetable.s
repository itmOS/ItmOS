section .text

%include "tty/tty.inc"
%include "util/macro.inc"
%include "dev/mem/mem_macro.inc"
%include "dev/mem/virtmem.inc"
%include "dev/mem/phymem.inc"
%include "dev/mem/bootmem.inc"

global init_kernel_page_table
global new_page_table
global dup_page_table
global free_page_table

;;; Creates new page table with mapped last 1 GB same as current
;;; void* new_page_table();
new_page_table:
        push ecx
        NEW_CLEAN_PHYSPAGE
        test eax, eax
        jnz .continue
        pop ecx
        ret
.continue:
        push eax
        push edx
        push edi
        push eax
        mov dword ecx, 768
.loop:
        cmp ecx, 1024
        je .exitloop
        ;; Get address of second level page table from kernels
        mov dword eax, [page_directory + 4 * ecx]
        mov dword [WINDOW + 4 * ecx], eax

        inc ecx
        jmp .loop
.exitloop:
        ;; Get second level page table for 4 MB
        NEW_CLEAN_PHYSPAGE
        test eax, eax
        jz .fail
        
        ;; Save its physical address
        mov ecx, eax
        ;; Get first level page table physical address
        pop eax
        ;; Map it to second window
        SAFE_WINDOW2 eax
        ;; Put second level page table for 4 MB in it
        push ecx
        ;; Flags
        or dword ecx, DEFAULT_ACCESS_MODE
        mov dword [WINDOW2], ecx
        pop ecx
        ;; Restore
        mov eax, ecx

        ;; Map second level page table except first 4 KB
        SAFE_WINDOW2 eax
        ;; Counter
        mov dword ecx, 1
.loop2:
        cmp ecx, 1024
        je .exit
        ;; Get page
        NEW_CLEAN_PHYSPAGE
        test eax, eax
        jz .fail
        ;; Add flags
        or dword eax, DEFAULT_ACCESS_MODE
        ;; And put it into second level table
        mov dword [WINDOW2 + 4 * ecx], eax

        inc ecx
        jmp .loop2
.exit:
        pop edi
        pop edx
        pop eax
        pop ecx
        ret
.fail:
        pop edi
        pop edx
        pop eax
        pop ecx
        CCALL free_page_table, eax
        xor eax, eax
        ret

;;; Duplicates page table(physical address): maps first 3GB to new pages and copies data; maps last 1 GB to same pages
;;; void* dup_page_table(void* table);
dup_page_table:
        push ecx
        NEW_CLEAN_PHYSPAGE
        test eax, eax
        jnz .continue
        pop ecx
        ret
.continue:
        push eax
        mov dword ecx, 768
.looploop:
        cmp ecx, 1024
        je .exitlooploop
        ;; Get address of second level page table from kernels
        mov dword eax, [page_directory + 4 * ecx]
        mov dword [WINDOW + 4 * ecx], eax

        inc ecx
        jmp .looploop
.exitlooploop:
        pop eax
        pop ecx
        
        ;; xchg bx, bx
        ;; Map givent page table
        mov dword ecx, [esp + 4]
        SAFE_WINDOW2 ecx

        ;; pointer answer is now in eax
        pusha

        ;; Save pointers to new page table and given page table
        mov edi, eax
        mov esi, ecx
        ;; Init only first 3 GB(last 1 GB is already mapped, same as kernel)
        mov dword ecx, 768
.loop:
        test ecx, ecx
        jz .exit
        dec ecx

        ;; Check if valid page present in source
        mov eax, [WINDOW2 + 4 * ecx]
        and dword eax, 1
        test eax, eax
        jnz .init
        ;; If not put 0 and continue
        mov dword [WINDOW + 4 * ecx], 0
        jmp .loop
.init:
        ;; If not present get page and init 
        NEW_CLEAN_PHYSPAGE
        test eax, eax
        jz .fail
        SAFE_WINDOW edi
        or eax, DEFAULT_ACCESS_MODE
        mov [WINDOW + 4 * ecx], eax
        ;; Than we need to remap second level pages in eax from ebx
        mov dword ebx, [WINDOW2 + 4 * ecx]
        mov dword eax, [WINDOW + 4 * ecx]
        mov ebp, eax
        ;; Map second level page tables
        SAFE_WINDOW eax
        SAFE_WINDOW2 ebx
        ;; Need to do same work, but with memcpy
        mov dword edx, 1024
.loop2:
        test edx, edx
        jz .finishloop
        dec edx
        
        push eax
        push ebx
        ;; Check if page is valid
        mov dword ebx, [WINDOW2 + 4 * edx]
        and dword ebx, 1
        test ebx, ebx
        jz .finishloop2
        ;; If not get page for initialization
        NEW_CLEAN_PHYSPAGE
        test eax, eax
        jz .fail
        SAFE_WINDOW ebp
        or eax, DEFAULT_ACCESS_MODE
        ;; Than need to memcpy content of source page to destination page
        mov dword [WINDOW + 4 * edx], eax
        mov dword ebx, [WINDOW2 + 4 * edx]
        ;; Remove flags
        and dword eax, ~0xFFF
        and dword ebx, ~0xFFF
        ;; Copy content
        push ecx
        CCALL memcpy_page, ebx, eax
        pop ecx

        pop ebx
        pop eax
        ;; Memcpy corrupted the window mapping so need to map second level pages again
        SAFE_WINDOW eax
        SAFE_WINDOW2 ebx
        jmp .loop2
.finishloop2:
        pop ebx
        pop eax
        jmp .loop2
.finishloop:
        ;; Finished with mapping second level page so return windows to current first level
        SAFE_WINDOW edi
        SAFE_WINDOW2 esi
        jmp .loop
.exit:
        popa
        ret
.fail:
        popa
        CCALL free_page_table, eax
        xor eax, eax
        ret

;;; Frees given page table(physical address): unmaps all virtual pages except last 1 GB
;;; void free_page_table(void*);
free_page_table:
        mov dword eax, [esp + 4]
        SAFE_WINDOW eax
        pusha
        ;; Save pointer to given page table
        mov edi, eax
        ;; Free only first 3 GB(last 1 GB is kernel)
        mov dword ecx, 768
.loop:
        test ecx, ecx
        jz .exit
        dec ecx

        ;; Check if valid page present
        mov eax, [WINDOW + 4 * ecx]
        and dword eax, 1
        test eax, eax
        jz .loop

        ;; Than we need to free second level pages in eax from edx
        mov dword eax, [WINDOW + 4 * ecx]
        ;; Map second level page tables
        SAFE_WINDOW2 eax
        mov dword edx, 1024
.loop2:
        test edx, edx
        jz .finishloop
        dec edx
        
        ;; Check if page is valid
        mov dword ebx, [WINDOW2 + 4 * edx]
        and dword ebx, 1
        test ebx, ebx
        jz .loop2
        ;; Free physical pages in second level
        mov dword ebx, [WINDOW2 + 4 * edx]
        and dword ebx, ~0xFFF
        push eax
        push ecx
        CCALL put_pages, ebx, dword 1
        pop ecx
        pop eax

        jmp .loop2
.finishloop:
        ;; Free second level page table 
        push eax
        push ecx
        CCALL put_pages, eax, dword 1

        pop ecx
        pop eax

        jmp .loop
.exit:
        ;; Free first level page table 
        push eax
        push ecx
        CCALL put_pages, edi, dword 1
        pop ecx
        pop eax
        popa
        ret

;;; Copies data of src physical page to dst physical page
;;; void memcpy(void* src, void* dst);
memcpy_page:
        ;; Map both to windows
        mov dword ecx, [esp + 4]
        SAFE_WINDOW ecx
        mov dword ecx, [esp + 8]
        SAFE_WINDOW2 ecx
        pusha
        ;; Copy 4 byte integer 1024 times
        mov ecx, 1024
.loop:
        test ecx, ecx
        jz .exit
        dec ecx

        mov dword eax, [WINDOW + ecx * 4]
        mov dword [WINDOW2 + ecx * 4], eax

        jmp .loop
.exit:
        popa
        ret

;;; Initializes kernel last 1 GB first level page table with second level page tables
init_kernel_page_table: 
        pusha

        mov dword ecx, 1024
.loop:
        cmp ecx, 768
        je .exit
        dec ecx
        ;; Check if valid page present
        mov eax, [page_directory + 4 * ecx]
        and dword eax, 1
        test eax, eax
        jz .init
        mov eax, [page_directory + 4 * ecx]
	jmp .loop
.init:
        ;; If not present get page and init 
        NEW_CLEAN_PHYSPAGE
        or eax, KERNEL_ACCESS_MODE
        mov [page_directory + 4 * ecx], eax
        jmp .loop
.exit:
        popa
        ret
