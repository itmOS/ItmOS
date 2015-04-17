section .text

%include "tty/tty.inc"
%include "ata/ata.inc"
%include "util/macro.inc"
%include "util/log/log.inc"
%include "util/test/test.inc"
%include "interrupts/interrupts_extern.inc"

global kernel_main
extern ata_register_tests
extern string_register_tests

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	call init_interrupts
        call logging_prelude

	TEST_REGISTER_SINGLE testing, simple_test
        call ata_register_tests
        call string_register_tests
	
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
	LOG_SIMPLE test_messages
	LOG_OK ok_message
	LOG_ERR err_message
	LOG_WARN warn_message
	LOG_SIMPLE real_logging
	ret

simple_test:
	;; This test checks nothing, should always pass
	xor eax, eax
	ret

section .data
prelude:	db '===== Booting ItmOS, be careful =====', 0
test_messages:	db 'Writing test logging messages, please check the colors', 0
ok_message:	db 'This is green and awesome', 0
err_message: 	db 'This is red and awful', 0
warn_message:   db 'This is yellow and scaring', 0
real_logging:	db 10,'Writing real log messages, please check if everything is OK',0

testing:	db 'KERNEL: Simple test',0

sprintf_test: db 'TTY: %u test %d', 10, 0

memin: times 600 dw 0
memout: times 600 dw 0
lba: dd 200

section .bss
stack:
        resd 0x1000
stack_top:
