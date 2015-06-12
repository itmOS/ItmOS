%ifndef UTIL_LIST_INC
%define UTIL_LIST_INC

%include "util/list/struct.inc"

;; list* list_single(void* e)
;; create the list with the signle element
extern list_single

;; void* list_head(list* l)
;; get the linked list head
extern list_head

;; void* list_tail(list* l)
;; get the linked list tail
extern list_tail

;; void list_free(list* l)
;; free the list
extern list_free

;; list* list_push(list* l, void* e)
;; push e in the front of l
extern list_push

;; void* list_pop(list* l)
;; pop the first element of the list
;; (like list_tail, buf also free the old vertex)
extern list_pop
%endif