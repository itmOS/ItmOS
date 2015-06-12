section .text

%include "tty/tty.inc"
%include "ata/ata.inc"
%include "util/macro.inc"
%include "util/log/log.inc"
%include "util/test/test.inc"
%include "interrupts/interrupts.inc"

global kernel_main
extern ata_register_tests
extern string_register_tests
extern list_register_tests

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	call init_interrupts
	call logging_prelude

	call ata_register_tests
	call string_register_tests
	call list_register_tests
	
	ATA_IDENTIFY

	TEST_RUN_ALL
	push dword -80
	push dword 70
	push sprintf_test
	CCALL tty_printf, sprintf_test, dword 70, dword -80
	pop eax
	pop eax
	pop eax
	jmp $

logging_prelude:
	LOG_SIMPLE prelude
	ret

section .data
prelude:	db '===== Booting ItmOS, be careful =====', 0

testing:	db 'KERNEL: Simple test',0

sprintf_test: db 'TTY: %u test %d', 10, 0

memin: times 600 dw 0
memout: times 600 dw 0
lba: dd 200

section .bss
stack:
		resd 0x1000
stack_top:
