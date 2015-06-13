%ifndef LIST_STRUCT_INC
%define LIST_STRUCT_INC

;; The linked list declaration
struc list
;; list* next
.next: resd 1
;; void* data
.data: resd 1
endstruc

%endif
