section .text

%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"

extern window

global page_count
global begin_page
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
        ;; TODO Check both addresses are page-aligned.
        ;; TODO Check if page directory is not allocated and handle
        push %1
        mov eax, %1
        ;; Get second level page table index 
        shr dword eax, 22

        ;; Get physical address of second level page table
        sal dword eax, 2
        add dword eax, [curr_page_dir]
        mov ecx, eax
        mov dword eax, [eax]

        ;; Check if second level page table is mapped
        test eax, eax
        jnz .mapping
        ;; If not get one physical page for it
        ;; TODO Check if result is not -1
        mov dword eax, 1
        CCALL get_pages, eax
        push eax
        ;; Initialize first level page table with this new address
        or eax, DEFAULT_ACCESS_MODE
        mov [ecx], eax
        pop eax
.mapping:
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

;;; Initializes manager with current page table address
;;; from  cr3
set_page_table:
        ;; Save current cr3 value
        mov eax, cr3
        mov [curr_page_dir], eax
        ;; TODO invalidate all TLB
        ret

init_mem_manager:
        pusha
        ;; Get iterator on list of memory regions
        BOOTINFO_GET_MMAP_ITER eax
        ;; TODO Remove to put_pages
        mov dword [begin_page], eax
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
        ;; TODO remove count changing to put_pages
        add dword [page_count], ecx
        ; Put region of given base address and length
        CCALL put_pages, ebx, ecx
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
        ;; ;; TODO check if address is page aligned
;;         ;; Check if begin page is zero that means that there were not free physical pages
;;         mov dword eax, [begin_page]
;;         test eax, eax
;;         jz .normal
;;         ;; Set new begin page address same as given base address
;;         mov dword eax, [esp + 4]
;;         mov [begin_page], eax
;;         ;; Set page count to given size
;;         mov dword ecx, [esp + 8]
;;         mov [page_count], ecx
;;         ;; Call mapping this block to WINDOW
;;         CCAL map_to_window, eax
;;         mov dword eax, [esp + 4]
;;         ;; Because we store memory structure just in memory
;;         ;; There are 3 uint32 in the begging of the physical memory block
;;         ;; They are: size in pages, previous block(or zero), next block(or zero)
;;         mov [eax], ecx
;;         mov [eax + 4], 0
;;         mov [eax + 8], 0
;;         ret
;; .normal:
;;         mov ecx, [begin_page]
;;         xor edx, edx
;;         ;; Need to determine the last block with address less than given, the first block greater than given
;; .loop:
;;         ;; Check if current block exists
;;         test ecx, ecx
;;         jz .finish_last

;;         CCAL map_to_window, ecx

;;         mov dword esi, [WINDOW]
;;         sal dword esi, 12
;;         add esi, ecx                    ; right bound of current block 

;;         mov dword eax, [esp + 4]        ; left bound of block to put
;;         mov dword edi, [esp + 8]
;;         sal dword esi, 12
;;         add edi, eax                    ; right bound of block to put

;;         cmp esi, eax
;;         jl .less

;;         cmp edi, ecx
;;         jnl .finish
;; .less:
;;         mov edx, ecx
;;         mov ecx, [WINDOW + 8]
;;         jmp .loop
;; .finish:



;; .first_bound:

;; .both_bounds:


;; .finish_last:
;;         ;; Previous block (address in edx is currently mapped to window)
;;         ;; In esi stored the right bound
;;         cmp esi, eax
;;         je .add_to prev

;;         CCAL map_to_window, eax
;;         mov dword esi, [esp + 8]
;;         mov [WINDOW], esi
;;         mov [WINDOW + 4], edx
;;         mov dword [WINDOW + 8], 0
;;         ret
;; .add_to_prev:
;;         mov dword edi, [esp + 8]
;;         add dword [WINDOW], edi
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
        invlpg [eax]            ; TODO Think if needed
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
;;; Address of the first block of physical memory
begin_page:             dd 0
;;; Amount of free pages
page_count:             dd 0
;;; Current virtual address of current first level page table
curr_page_dir:          dd 0
