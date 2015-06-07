section .text

%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"

extern window
extern get_pages
extern put_pages

global begin_page
global map_to_window
global init_mem_manager

KERNEL_PHY              equ 0x400000
PAGE_SIZE               equ 0x1000
PAGE_SIZE_OFFSET        equ 12
WINDOW                  equ 0xFFFFF000
WINDOW_PAGE_NUMBER      equ 1023
DEFAULT_ACCESS_MODE     equ 0x7

;;; If current page directory stored in curr_page_dir and mapped
;;; Return virtual address of memory with page table entry mapping it to WINDOW page
;;; in eax
%macro PAGE_ENTRY_POINTER 1
        push %1
        mov eax, %1
        ;; Get second level page table index 
        shr dword eax, 22

        ;; Get physical address of second level page table
        sal dword eax, 2
        ;; Get current page table physical address
        mov ecx, cr3
        ;; Map it to window
        CCALL map_to_window, ecx
        add dword eax, WINDOW 
        mov ecx, eax
        mov dword eax, [eax]

        ;; Check if second level page table is mapped
        test eax, eax
        jnz %%mapping
        ;; If not get one physical page for it
        ;; TODO Check if result is not -1
        mov dword eax, 1
        CCALL get_pages, eax
        push eax
        ;; Initialize first level page table with this new address
        or eax, DEFAULT_ACCESS_MODE
        mov [ecx], eax
        pop eax
%%mapping:
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
        ;; Get iterator on list of memory regions
        BOOTINFO_GET_MMAP_ITER eax
.loop:
        
        mov ebx, BOOTINFO_MMAP_TYPE(eax)
        test ebx, ebx
        jz .exit

        ;; Check if region is free to use
        mov ebx, BOOTINFO_MMAP_TYPE(eax)
        cmp ebx, 1
        jne .finish

        ;; Check if 0-4MB lays in block
        mov ebx, BOOTINFO_MMAP_LENGTH(eax)
        add ebx, BOOTINFO_MMAP_BASEADDR(eax)
        mov ecx, BOOTINFO_MMAP_BASEADDR(eax)
        ;; Check if begining is after 4MB
        cmp ecx, KERNEL_PHY
        ;; If so do nothing
        jnl .normal
        ;; Check if the end is after 4MB
        cmp ebx, KERNEL_PHY
        ;; If not block must not be used at all
        jng .finish

        ;; Setting new length and base address
        ;; Getting length difference
        mov ebx, BOOTINFO_MMAP_BASEADDR(eax)
        sub ebx, KERNEL_PHY
        ;; Get new length
        mov ecx, BOOTINFO_MMAP_LENGTH(eax)
        sub ecx, ebx
        ;; Set base address to 4MB
        mov ebx, KERNEL_PHY
        jmp .set
.normal:
        ;; Get base address of memory region
        mov ecx, BOOTINFO_MMAP_BASEADDR(eax)
        ;; Get length in bytes
        mov ecx, BOOTINFO_MMAP_LENGTH(eax)
.set:
        ;; Get length in pages
        shr ecx, 12
        ; Put region of given base address and length
        CCALL put_pages, ebx, ecx
.finish:
        BOOTINFO_MMAP_NEXT eax
        jmp .loop
.exit:
        popa
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
        mov dword edx, [esp + 8]

        PAGE_ENTRY_POINTER edx
        ;; TODO check if pointer is not -1
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
        ;; TODO check if pointer is not -1
        push eax
        mov eax, [eax]
        and eax, WINDOW
        mov dword ecx, 1
        CCALL put_pages, eax, ecx
        pop eax
        mov dword [eax], 0
        invlpg [eax]
        ret

;;; Return address of physical page mapped in given virtual page address
;;; get_phys_page(virtaddr)
get_phys_page:  
        mov dword ecx, [esp + 4]

        PAGE_ENTRY_POINTER ecx
        ;; TODO check if pointer is not -1

        ;; Get phys page
        mov dword edx, [eax]
        and dword edx, ~0xFFF
        ;; Get offset
        mov eax, [esp + 4]
        and dword eax, 0xFFF
        add eax, edx
        ret


align 4
begin_page:             dd 0    ; first free block of physical memory
