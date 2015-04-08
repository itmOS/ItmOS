section .text

extern init_interrupts

%include "tty/tty.inc"
%include "ata/ata.inc"
%include "aux/log/log.inc"
%include "aux/test/test.inc"

global kernel_main
extern c_register_tests

;;; Entry point of the kernel.
kernel_main:
	mov esp, stack_top
	call init_interrupts
	call logging_prelude

	TEST_REGISTER_SINGLE testing, simple_test
	call c_register_tests
	
	ATA_IDENTIFY
	mov [memout + 0], byte 's'
	mov [memout + 1], byte 'u'
	mov [memout + 2], byte 'c'
	mov [memout + 3], byte 'c'
	mov [memout + 4], byte 'e'
	mov [memout + 5], byte 's'
	mov [memout + 6], byte 's'
	mov [memout + 7], byte 10
	mov [memout + 8], byte 0
	mov [memout + 300], byte 'y'
	mov [memout + 301], byte 'e'
	mov [memout + 302], byte 's'
	mov [memout + 303], byte 10
	mov [memout + 304], byte 0
	ATA_PIO_OUTSEG [lba], memout, 2
	ATA_PIO_INSEG [lba], memin, 2
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), memin
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), memin + 300

	TEST_RUN_ALL
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

memin: times 600 dw 0
memout: times 600 dw 0
lba: dd 200

section .bss
stack:
        resd 0x1000
stack_top:
