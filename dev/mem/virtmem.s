section .text

%include "multiboot/multiboot.inc"
%include "tty/tty.inc"
%include "util/macro.inc"
%include "dev/mem/phymem.inc"
%include "dev/mem/bootmem.inc"
%include "dev/mem/mem_macro.inc"

global begin_page
global map_to_window
global map_to_window2
global init_mem_manager
global map_page
global unmap_page
global get_physaddr

init_mem_manager:
        LOCK_MUTEX
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
        mov edi, BOOTINFO_MMAP_BASEADDR(eax)
        mov ebx, KERNEL_PHY
        sub ebx, edi
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
        push eax
        push ecx
        CCALL put_pages, ebx, ecx
        pop ecx
        pop eax
.finish:
        BOOTINFO_MMAP_NEXT eax
        jmp .loop
.exit:
        popa
        UNLOCK_MUTEX
        ret

;;; Maps phyaddr to window virtaddr
map_to_window:  
        mov eax, [esp + 4]
        or eax, KERNEL_ACCESS_MODE
        mov [window], eax
        invlpg [WINDOW]
        ret

;;; Maps phyaddr to window virtaddr
map_to_window2:  
        mov eax, [esp + 4]
        or eax, KERNEL_ACCESS_MODE
        mov [window2], eax
        invlpg [WINDOW2]
        ret

;;; Maps page phyaddr to virtadr with flags
;;; int map_page(void*  virtaddr, void* phyaddr, int flags)
map_page:
        LOCK_MUTEX
        ;; xchg bx, bx

        push ecx
        push edx
        mov dword eax, [esp + 12]
        mov dword edx, [esp + 16]
        mov dword ecx, [esp + 20]
        push ebx
        push edi
        push eax
        mov edi, ecx
        and dword eax, WINDOW

        ;; Get current page table physical address and map it to window
        mov ecx, cr3
        SAFE_WINDOW ecx

        ;; Get index of second level page table
        ;; Get physical address of second level page table address
        shr dword eax, 22
        and dword eax, 0x3FF
        sal dword eax, 2
        add dword eax, WINDOW

        mov dword ecx, [eax]
        ;; Check if valid
        and dword ecx, 1
        ;; If not valid map physical page
        test ecx, ecx
        jnz .nomap
        push eax
        mov ebx, eax
        NEW_CLEAN_PHYSPAGE

        mov ecx, cr3
        SAFE_WINDOW ecx
        ;; Initialize first level page table with this new address
        mov ecx, edi
        and dword ecx, 0xFFF
        or eax, ecx
        mov [ebx], eax
        pop eax
.nomap:
        mov dword ecx, [eax]
        and dword ecx, WINDOW
        SAFE_WINDOW ecx
        pop eax
        mov ecx, eax

        shr dword eax, 12
        and dword eax, 0x3FF

        sal dword eax, 2
        add dword eax, WINDOW

        and dword edx, WINDOW
        and dword edi, 0xFFF
        or dword edx, edi

        mov [eax], edx

        ;; Flushing to TLB
        invlpg [ecx]

        ;; Return zero if success
        xor eax, eax
.exit:
        pop edi
        pop ebx
        pop edx
        pop ecx
        UNLOCK_MUTEX
        ret
.fail:
        mov dword eax, -1
        jmp .exit

;;; Return address of physical page of given virtual page
;;; void* get_physaddr(virtaddr);
get_physaddr:  
        LOCK_MUTEX
        ;; xchg bx, bx
        mov dword eax, [esp + 4]
        push ecx
        push eax
        and dword eax, WINDOW

        ;; Get current page table physical address and map it to window
        mov ecx, cr3
        SAFE_WINDOW ecx

        ;; Get index of second level page table
        shr dword eax, 22
        and dword eax, 0x3FF
        ;; Get physical address of second level page table address
        sal dword eax, 2
        add dword eax, WINDOW

        mov dword ecx, [eax]
        mov eax, ecx
        ;; Check if valid
        and dword eax, 1
        ;; If not valid return 0
        test eax, eax
        jnz .answer
        pop eax
        xor eax, eax
        pop ecx
        UNLOCK_MUTEX
        ret
.answer:
        and dword ecx, WINDOW
        SAFE_WINDOW ecx

        pop eax
        shr dword eax, 12
        and dword eax, 0x3FF

        sal dword eax, 2
        add dword eax, WINDOW

        mov dword eax, [eax]
	mov ecx, eax
	and dword ecx, 1
	test ecx, ecx
	jnz .exit
	xor eax, eax
.exit:
        and dword eax, ~0xFFF

        pop ecx
        UNLOCK_MUTEX
        ret

;;; Unmaps page with given address
;;; unmap_page(virtaddr)
unmap_page:     
        LOCK_MUTEX
        ;; xchg bx, bx
        mov dword eax, [esp + 4]
        push ecx
        push edx
        push eax
        and dword eax, WINDOW

        ;; Get current page table physical address and map it to window
        mov ecx, cr3
        SAFE_WINDOW ecx

        ;; Get index of second level page table
        shr dword eax, 22
        and dword eax, 0x3FF
        ;; Get physical address of second level page table address
        sal dword eax, 2
        add dword eax, WINDOW

        mov dword ecx, [eax]
        mov eax, ecx
        ;; Check if valid
        and dword eax, 1
        ;; If not valid return 0
        test eax, eax
        jnz .answer
        pop eax
        pop edx
        pop ecx
        UNLOCK_MUTEX
        ret
.answer:
        and dword ecx, WINDOW
        SAFE_WINDOW ecx
        pop eax
        mov edx, eax
        
        shr dword eax, 12
        and dword eax, 0x3FF

        sal dword eax, 2
        add dword eax, WINDOW

        mov dword ecx, [eax]
        and dword ecx, ~0xFFF

        mov dword [eax], 0
        invlpg [edx]

        and dword ecx, WINDOW
	test ecx, ecx
	jz .exit
        CCALL put_pages, ecx, dword 1
.exit:
        pop edx
        pop ecx
        UNLOCK_MUTEX
        ret

align 4
begin_page:             dd 0    ; first free block of physical memory
mutex:                  db 0
