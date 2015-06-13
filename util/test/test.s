;;; This is the ItmOS testing framework.

%include "util/log/log.inc"
%include "util/test/test_t.inc"

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
;;; FIXME: Better output when the printf will be fixed
test_run_all:	
	push ecx
	push esi
	push edi
	push edx

	xor edx, edx		; how many tests failed
	push ecx
	LOG_SIMPLE starting_tests
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
	inc edx
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

	;; TODO: Print how many tests failed
	LOG_SIMPLE tests_finished

	pop edx
	pop edi
	pop esi
	pop ecx
	ret

section .data
single_tests_count: dd 0
starting_tests: db '===== Running tests =====', 0
tests_finished: db '===== Tests finished =====', 0
test_passed: db '[PASSED] %s', 10, 0
test_failed: db '[FAILED] %s', 10, 0

section .bss
;;; FIXME: Make the size infinite when adding dynamic memory
single_tests: resb 1024 * test_t.sizeof
