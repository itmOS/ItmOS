section .text

global page_count
extern memory_map

;; Memory map structure fields:
%define BOOTINFO_MMAP_BASEADDR(a) [a + 4] ; Base address of the region
%define BOOTINFO_MMAP_LENGTH(a) [a + 12] ; Region length
%define BOOTINFO_MMAP_TYPE(a) [a + 20] ; 1 for RAM, other for reserved

;; Get next memory map structure
%macro BOOTINFO_MMAP_NEXT 1
        add %1, dword [%1]
%endmacro


init_mem_manager:
        pusha
        mov eax, [memory_map]
.loop:
        mov ebx, BOOTINFO_MMAP_BASEADDR(eax)
        test ebx, ebx
        jz .exit

        mov ebx, BOOTINFO_MMAP_TYPE(eax)
        cmp ebx, 1
        jne .finish

        mov ebx, BOOTINFO_MMAP_BASEADDR(eax)
        cmp ebx, 0x100000
        jl .finish

        mov ebx, BOOTINFO_MMAP_BASEADDR(eax)
        mov ecx, BOOTINFO_MMAP_LENGTH(eax)
        shl ecx, 12
        push ebx
        push ecx
        call put_pages
        pop ecx
        pop ebx

        mov ecx, BOOTINFO_MMAP_LENGTH(eax)
        add [page_count], ecx

.finish:
        BOOTINFO_MMAP_NEXT eax

.exit:
        popa
        ret

;;; Takes amount of pages and return address of memory block if given size
;;; Returns -1 if amount of free memory is less
;;; Return -1 if there is no coherent block of input size
;;; If memory needed can be divided use get_one_page
get_pages:
        ret

;;; put_pages(address, size)
;;; Sets given amount of pages beginning from given address free
put_pages:
        ret

;;; Return address to one page of physical memory
;;; Returns -1 if there are no pages
get_one_page:
        ret

;;; put_one_page(address)
;;; Sets page from given address free
put_one_page:
        ret


temp_map_page:
        ret

map_pages:
        ret

        
get_page_info:  
        ret


;;; Address of the first block
begin_page:     dw 0
;;; Amount of free pages
page_count:     dw 0
