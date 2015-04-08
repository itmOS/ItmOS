;;; Structures and macros for the ItmOS testing framework
;;; see aux/test/test.s

%ifndef AUX_TEST_INC
%define AUX_TEST_INC

%include "aux/test/test_t.inc"

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

%endif 				; AUX_TEST_INC
