; Declare constants used for creating a multiboot header.
MBALIGN     equ  1<<0                   ; align loaded modules on page boundaries
MEMINFO     equ  1<<1                   ; provide memory map
FLAGS       equ  MBALIGN | MEMINFO      ; this is the Multiboot 'flag' field
MAGIC       equ  0x1BADB002             ; 'magic number' lets bootloader find the header
CHECKSUM    equ -(MAGIC + FLAGS)        ; checksum of above, to prove we are multiboot
 
section .multiboot
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
 
; Currently the stack pointer register (esp) points at anything and using it may
; cause massive harm. Instead, we'll provide our own stack. We will allocate
; room for a small temporary stack by creating a symbol at the bottom of it,
; then allocating 16384 bytes for it, and finally creating a symbol at the top.
section .bootstrap_stack
align 4
stack_bottom:
times 16384 db 0
stack_top:
 
; The linker script specifies _start as the entry point to the kernel and the
; bootloader will jump to this position once the kernel has been loaded. It
; doesn't make sense to return from this function as the bootloader is gone.
section .text
global _start
_start:
	; To set up a stack, we simply set the esp register to point to the top of
	; our stack (as it grows downwards).
	mov esp, stack_top

	; Call our kernel's main function
	extern kernel_main
	call kernel_main
 
	; In case the function returns, we'll want to put the computer into an
	; infinite loop. To do that, we use the clear interrupt ('cli') instruction
	; to disable interrupts, the halt instruction ('hlt') to stop the CPU until
	; the next interrupt arrives, and jumping to the halt instruction if it ever
	; continues execution, just to be safe.
	cli
.hang:
	hlt
	jmp .hang
