section .text

%include "boot/boot.inc"
%include "multiboot/multiboot.inc"

;;; Multiboot constants http://nongnu.askapache.com/grub/phcoder/multiboot.pdf
MODULEALIGN equ  1<<0
MEMINFO		equ  1<<1
FLAGS		equ  MODULEALIGN | MEMINFO
MAGIC		equ    0x1BADB002
CHECKSUM	equ -(MAGIC + FLAGS)

;;; Present, Read/Write and user accessible
;;; See http://wiki.osdev.org/Paging
DEFAULT_ACCESS_MODE             equ 0x7
KERNEL_PAGE_NUMBER	        equ (KERNEL_VMA >> 22) ; Page directory index of kernel's 4MB PTE.
STACK_SIZE			equ 0x4000			   ; 16k

section .text

align 4
multiboot_header:
		dd MAGIC
		dd FLAGS
		dd CHECKSUM

global _loader
global memory_map
global page_directory
global window
global window2
global last_page_dir
_loader:
    ;; Disable interrupts
    cli

	;; Load descriptors table
	lgdt [gdt32.ptr - KERNEL_VMA]

	mov ax, 16
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	;; FIXME: Next line does not fail WTF?
	mov ss, ax

    ;; Set up page table
    mov eax, (page_directory - KERNEL_VMA)
    mov cr3, eax

    ;; Set PSE bit in CR4 to enable 4MB pages.
    mov ecx, cr4
    or ecx, 0x00000010
    mov cr4, ecx

    ;; Turn on paging
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

	;; Save boot info address
	BOOTINFO_LOAD ebx

	;; Start fetching instructions in kernel space.
    ;; Since eip at this point holds the physical address of this command (approximately 0x00100000)
    ;; we need to do a long jump to the correct virtual address of the next instruction which is
    ;; approximately 0xC0100000.
	jmp 8:.continue

.continue:
    ;; Why not get rid of that duct tape?
    ;mov byte [page_directory + 7], 0

    mov edi, gdt32.tss
    extern init_tss
    call init_tss

    extern kernel_main
    jmp kernel_main

section .data
;;; The first 3G of the memory will be controlled by user,
;;; when the rest of space will be kernel's memory in every process.
;;; Also we map the first 1M one-by-one, to continue correct execution of the loaded code after setting the page table.
;;; We assume that kernel is loaded to the address 0x100000
align 4096
page_directory:
		;; This page directory entry identity-maps the first 4MB of the 32-bit physical address space.
		;; All bits are clear except the following:
		;; bit 7: PS The kernel page is 4MB.
		;; bit 1: RW The kernel page is read/write.
		;; bit 0: P  The kernel page is present.
		;; This entry must be here -- otherwise the kernel will crash immediately after paging is
		;; enabled because it can't fetch the next instruction! It's ok to unmap this page later.
		dd 0x00000087
		times (KERNEL_PAGE_NUMBER - 1) dd 0
		dd 0x00000083
		times (1024 - KERNEL_PAGE_NUMBER - 2) dd 0
		dd (last_page_dir + DEFAULT_ACCESS_MODE  - KERNEL_VMA) ; mapping last page directory for 4 KB pages
last_page_dir: 
	        times (1024 - 2) dd 0
window2:
                dd 0
                ;; saving pointer to the last page to use it as a window
window:
                dd 0

;;; GDT for the 32-bit kernel
align 16
gdt32:
        dq 0                    ; NULL - 0
        dq 0x00CF9A000000FFFF   ; CODE - 8
        dq 0x00CF92000000FFFF   ; DATA - 16
        dq 0x00CBFA000000FFFF   ; userspace code - 24 | 3 = 27
        dq 0x00CBF2000000FFFF   ; userspace data - 32 | 3 = 35
.tss:   dq 0 ; It is an empty TSS descriptor. Just wait.
.ptr:
		dw $ - gdt32 - 1
		dd (gdt32 - KERNEL_VMA)
