%include 'util/list/struct.inc'

global list_single
;; list* list_single(void* e)
list_single:
	push ebp
	mov ebp, esp

	push esi
	mov esi, [ebp + 8]

	call get_node
	mov [eax + list.data], esi
	mov dword [eax + list.next], 0

	pop esi

	pop ebp
	ret

global list_head
;; void* list_head(list* l)
list_head:
	mov eax, [esp + 4]
	mov eax, [eax + list.data]
	ret

global list_tail
;; list* list_tail(list* l)
list_tail:
	mov eax, [esp + 4]
	mov eax, [eax + list.next]
	ret

;; void list_free(list* l)
global list_free
list_free:
	;; TODO: Ignoring fow now
	ret

;; list* list_push(list* l, void* e)
global list_push
list_push:
	push ebx

	mov ebx, [esp + 8]
	call get_node
	mov [eax + list.next], ebx
	mov ebx, [esp + 12]
	mov [eax + list.data], ebx

	pop ebx
	ret

message: db 'HERE: %d',10, 0

;; list* list_pop(list* l)
global list_pop
list_pop:
	mov eax, [esp + 4]
	mov eax, [eax + list.next]

	;; TODO: Free when adding dynamic memory
	ret

;; list* get_node()
;; Allocates the new node
get_node:
	inc dword [ptr]
	cmp dword [ptr], MAX_SIZE
	jb .not_overflow
	mov dword [ptr], 0
	.not_overflow:
	mov eax, [ptr]
	lea eax, [eax * list_size + storage]
	ret

section .data
MAX_SIZE: equ 4096
;; TODO: Remove when will add the dynamic memory
storage: resb MAX_SIZE * list_size
ptr: dd 0
