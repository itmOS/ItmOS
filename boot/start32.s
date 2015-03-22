section .text

extern kernel_main

global boot_start32
boot_start32:   
        ;; Disable interrupts
        cli

        ;; Load descriptors table
        lgdt [gdt32.ptr]

        ;; Set up the segment registers to point on
        ;; the new segments
        mov ax, 16
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax

        call kernel_main
        
;;; GDT for the 32-bit kernel
align 16
gdt32:
	dq 0                    ; NULL - 0
	dq 0x00CF9A000000FFFF   ; CODE - 8
	dq 0x00CF92000000FFFF   ; DATA - 16
.ptr:
	dw $ - gdt32 - 1
	dd gdt32
