section .text

%include "tty/tty.inc"
%include "ata/ata.inc"
%include "util/macro.inc"
%include "util/log/log.inc"
%include "util/test/test.inc"
%include "interrupts/interrupts.inc"
%include "multiboot/multiboot.inc"
%include "kernel/syscalls/syscalls.inc"
%include "kernel/io/io.inc"

global kernel_main
extern ata_register_tests
extern string_register_tests
extern list_register_tests
extern kbd_register_tests
extern pipe_register_tests
extern pipe_obj_register_tests
extern hash_register_tests
extern fs_register_tests
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
	mov esp, stack_top

        ;; xchg bx, bx

        call init_mem_manager
        call init_kernel_page_table
	call init_interrupts
	call logging_prelude

	call ata_register_tests
	call string_register_tests
	call list_register_tests
	call mem_register_tests
	call kbd_register_tests
	call pipe_register_tests
	call pipe_obj_register_tests
	call hash_register_tests
	call fs_register_tests
	call io_initialize

	ATA_IDENTIFY

	call init_syscalls
	TEST_RUN_ALL
	push dword -80
	push dword 70
	push sprintf_test
	CCALL tty_printf, sprintf_test, dword 70, dword -80
	add eax, 12
	TTY_PUTS processes

	extern sch_bootstrap
	jmp sch_bootstrap

logging_prelude:
	LOG_SIMPLE prelude
	ret

section .data
prelude:	db '===== Booting ItmOS, be careful =====', 0

testing:	db 'KERNEL: Simple test',0

processes: db 'Running two processes printing letters:', 10, 0

memory_test:    db "%u", 10, 0

sprintf_test: db 'TTY: %u test %d', 10, 0

memin: times 600 dw 0
memout: times 600 dw 0
lba: dd 200

section .bss
stack:
		resd 0x1000
stack_top:
