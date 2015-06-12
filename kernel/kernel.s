section .text

%include "tty/tty.inc"
%include "ata/ata.inc"
%include "util/macro.inc"
%include "util/log/log.inc"
%include "util/test/test.inc"
%include "interrupts/interrupts.inc"
%include "multiboot/multiboot.inc"

global kernel_main
extern ata_register_tests
extern string_register_tests

extern mem_register_tests
extern init_mem_manager
extern mmap_print
extern init_kernel_page_table
extern page_directory
extern get_pages
extern map_page
extern dup_page_table
extern new_page_table
extern free_page_table


;;; Entry point of the kernel.
kernel_main:
	xchg bx, bx
	mov esp, stack_top
	call init_interrupts
        call init_mem_manager
        call init_kernel_page_table

        call logging_prelude
        call ata_register_tests
        call mem_register_tests
        call string_register_tests
	
        ATA_IDENTIFY

        TEST_RUN_ALL
        xchg bx, bx

	jmp $

logging_prelude:
	LOG_SIMPLE prelude
	ret

section .data
prelude:	db '===== Booting ItmOS, be careful =====', 0

testing:	db 'KERNEL: Simple test',0

memory_test:    db "%u", 10, 0

sprintf_test: db 'TTY: %u test %d', 10, 0

memin: times 600 dw 0
memout: times 600 dw 0
lba: dd 200

section .bss
stack:
		resd 0x1000
stack_top:
