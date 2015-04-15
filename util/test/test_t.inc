%ifndef UTIL_TEST_TEST_T_INC
%define UTIL_TEST_TEST_T_INC

;;; To create test write
;;; 
;;; This function should return int (exit_code)
;;; test_function:
;;;   bla-bla
;;;   ret
;;; 
;;; the_best_description: "THE_GREAT_MODULE: The best test over the world", 0
;;; 
;;; ........
;;; Somewhere in the code:
;;; TEST_REGISTER_SINGLE(the_best_description, my_awesome_test)
struc test_t
.name: resd 1 		; name of the test
.ptr: resd 1		; pointer to the function
.sizeof:
endstruc

%endif ; UTIL_TEST_TEST_T_INC
