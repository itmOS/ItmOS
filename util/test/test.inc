;;; Structures and macros for the ItmOS testing framework
;;; see util/test/test.s

%ifndef UTIL_TEST_INC
%define UTIL_TEST_INC

%include "util/test/test_t.inc"

extern test_register_single
extern test_run_all

%macro TEST_REGISTER_SINGLE 2
	push %2
	push %1
	call test_register_single
	add esp, 8
%endmacro

%macro TEST_RUN_ALL 0
call test_run_all
%endmacro

%endif 				; UTIL_TEST_INC
