;;; This is the ItmOS testing framework.

%include "util/log/log.inc"
%include "util/test/test_t.inc"
%include "util/macro.inc"

global test_register_single
global test_run_all

section .text

;;; void test_register_single(char* name,
;;;                           int (test_body*)(void));
;;; Register the single test (e.g. without a group).
test_register_single:
	push ebp
	mov ebp, esp
	push ebx
	push ecx

	mov ecx, [single_tests_count]
	mov ebx, [ebp + 8]
	mov [single_tests + ecx * test_t.sizeof + test_t.name], ebx
	mov ebx, [ebp + 12]
	mov [single_tests + ecx * test_t.sizeof + test_t.ptr], ebx

	inc dword [single_tests_count]

	pop ecx
	pop ebx
	pop ebp
	ret

;;; void test_run_all(void);
;;; Run all registered tests.
test_run_all:
	push ebp
	mov ebp, esp
	push dword 0

	push ecx
	push esi
	push edi
	push edx

	push ecx
	TTY_SAVE_STYLE
	TTY_SET_STYLE TTY_STYLE(TTY_BLACK, TTY_BLUE)
	LOG_SIMPLE starting_tests
	TTY_RESTORE_STYLE
	pop ecx

	xor ecx, ecx
	.loop:
	mov edi, [single_tests + ecx * test_t.sizeof + test_t.name]
	push ecx
	;;LOG_SIMPLE edi
	pop ecx

	mov esi, [single_tests + ecx * test_t.sizeof + test_t.ptr]
	push ecx
	call esi
	pop ecx
	test eax, eax
	jz .test_passed
	;; Test failed
	push ecx
	push edi
	push test_failed
	TTY_SAVE_STYLE
	TTY_SET_STYLE TTY_STYLE(TTY_BLACK, TTY_RED)
	call tty_printf
	TTY_RESTORE_STYLE
	add esp, 4
	pop edi
	pop ecx
	inc dword [ebp - 4]
	jmp .continue

	.test_passed
	push ecx
	push edi
	push test_passed
	TTY_SAVE_STYLE
	TTY_SET_STYLE TTY_STYLE(TTY_BLACK, TTY_GREEN)
	call tty_printf
	TTY_RESTORE_STYLE
	add esp, 4
	pop edi
	pop ecx

	.continue

	inc ecx
	cmp ecx, [single_tests_count]
	jl .loop

	mov edx, [ebp - 4]
	TTY_SAVE_STYLE
	test edx, edx
	jne .failed
	TTY_SET_STYLE TTY_STYLE(TTY_BLACK, TTY_GREEN)
	TTY_PUTS all_tests_passed
	jmp .exit
	.failed:
	TTY_SET_STYLE TTY_STYLE(TTY_BLACK, TTY_RED)
	push edx
	push some_tests_failed
	call tty_printf
	add esp, 8

	.exit:
	TTY_RESTORE_STYLE

	pop edx
	pop edi
	pop esi
	pop ecx

	add esp, 4
	pop ebp
	ret

section .data
single_tests_count: dd 0
starting_tests: db '===== Running tests =====', 0
some_tests_failed: db '===== %u tests failed ====', 10, 0
all_tests_passed: db '===== All tests passed =====', 10, 0
test_passed: db '[PASSED] %s', 10, 0
test_failed: db '[FAILED] %s', 10, 0

section .bss
;;; FIXME: Increase the size in future, or make it dynamic
single_tests: resb 1024 * test_t.sizeof
