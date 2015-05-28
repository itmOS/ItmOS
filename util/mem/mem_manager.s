section .text

%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"

extern page_directory
extern window

global page_count
global begin_page
global init_mem_manager

BASE_M                  equ 0x100000
PAGE_SIZE               equ 0x1000
PAGE_SIZE_BIG           equ 0x4000000
PAGE_SIZE_OFFSET        equ 12
WINDOW                  equ 0xFFFFF000
WINDOW_PAGE_NUMBER      equ 1023
DEFAULT_ACCESS_MODE     equ 0x7

;;; If current page directory stored in kernel_page_dir and mapped
;;; Return virtual address of memory with page table entry mapping it to WINDOW page
;;; in eax
%macro PAGE_ENTRY_POINTER 1
        push %1
        mov eax, %1
        ;; Get second level page table index 
        shr dword eax, 22

        ;; Get physical address of second level page table
        sal dword eax, 2
        add dword eax, [kernel_page_dir]
        mov dword eax, [eax]

        ;; Map page containing second level page table we need to WINDOW
        push eax
        and eax, WINDOW
        CCALL map_to_window, eax
        pop eax
        ;; Put in eax current virtual address of second level table
        or eax, WINDOW
        
        ;; Get index of entry in second level page table
        pop ecx
        shr dword ecx, 12
        and dword ecx, 0x03FF
        ;; Get virtual address of page table entry
        sal dword ecx, 2
        add eax, ecx
%endmacro

init_mem_manager:
        pusha
        mov eax, cr3
        mov [kernel_page_dir], eax                      ; save current cr3 value
        
        BOOTINFO_GET_MMAP_ITER eax                      ; get iterator on list of memory regions
        mov dword [begin_page], eax
.loop:
        
        mov ebx, BOOTINFO_MMAP_TYPE(eax)
        test ebx, ebx
        jz .exit

        mov ebx, BOOTINFO_MMAP_TYPE(eax)                ; check if region is free to use
        cmp ebx, 1
        jne .finish

        mov ebx, BOOTINFO_MMAP_BASEADDR(eax)            ; get base address of memory regiont
        cmp ebx, BASE_M
        jl .finish
        
        mov ecx, BOOTINFO_MMAP_LENGTH(eax)              ; get length in bytes
        shr ecx, 12                                     ; length in pages
        CCALL put_pages, ebx, ecx                       ; call put region of given address and length

        mov ecx, BOOTINFO_MMAP_LENGTH(eax)              ; add length of region to page_count
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
        cmp dword [page_count], 0
        je .init
.init:
        mov dword eax, [esp + 4]
        mov [kernel_page_dir], eax
        mov dword eax, [esp + 8]
        mov [page_count], eax

.exit:
        ret

;;; Return address to one page of physical memory
;;; Returns -1 if there are no pages
get_one_page:
        ret

;;; put_one_page(address)
;;; Sets page from given address free
put_one_page:
        ret

;;; Maps phyaddr to window virtaddr
map_to_window:  
        mov eax, [esp + 4]
        or eax, 0x7
        mov [window], eax
        invlpg [WINDOW]
ret


;;; Maps page phyaddr to virtadr with flags
;;; map_page(phyaddr, virtaddr, flags)
map_page:
        ;; TODO Check both addresses are page-aligned.
        ;; TODO Check if page directory is not allocated and handle
        mov dword edx, [esp + 8]

        PAGE_ENTRY_POINTER edx
        
        mov edx, [esp + 4]                                      ; get phys addr
        mov ecx, [esp + 12]
        and dword ecx, 0xFFF                                    ; flags
        or edx, ecx
        or dword edx, 0x01
        ;; set
        mov [eax], edx

        ;; Flushing to TLB
        mov dword eax, [esp + 8]
        invlpg [eax]
        ret

;;; Unmaps page with given address
;;; get_phys_page(virtaddr)
unmap_page:     
        mov dword ecx, [esp + 4]
        PAGE_ENTRY_POINTER ecx
        mov dword [eax], 0
        ret

;;; Return address of physical page mapped in given virtual page address
;;; get_phys_page(virtaddr)
get_phys_page:  
        mov dword ecx, [esp + 4]
        PAGE_ENTRY_POINTER ecx
        ;; Get phys page
        mov dword edx, [eax]
        and dword edx, ~0xFFF
        ;; Get offset
        mov eax, [esp + 4]
        and dword eax, 0xFFF
        add eax, edx
        ret


;;; Address of the first block
begin_page:             dd 0
;;; Amount of free pages
page_count:             dd 0
kernel_page_dir:        dd 0
