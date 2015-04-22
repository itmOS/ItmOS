section .text

%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"

global page_count
global begin_page
global init_mem_manager

BASE_M          equ 0x100000

init_mem_manager:
        pusha
        BOOTINFO_GET_MMAP_ITER eax
        mov dword [begin_page], eax
.loop:
        
        mov ebx, BOOTINFO_MMAP_TYPE(eax)
        test ebx, ebx
        jz .exit

        mov ebx, BOOTINFO_MMAP_TYPE(eax)
        cmp ebx, 1
        jne .finish

        mov ebx, BOOTINFO_MMAP_BASEADDR(eax)
        cmp ebx, BASE_M
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
        add dword [page_count], ecx

.finish:
        BOOTINFO_MMAP_NEXT eax
        jmp .loop

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
begin_page:     dd 0
;;; Amount of free pages
page_count:     dd 0
