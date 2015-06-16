%include 'util/list/struct.inc'
%include 'stdlib.inc'

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
	mov eax, [esp + 4]
	push ebx

.loop:
	test eax, eax
	je .end_loop

	mov ebx, [eax + list.next]

	push eax
	call free
	add esp, 4

	mov eax, ebx
	jmp .loop

.end_loop:
	pop ebx
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
	push ebx

	mov eax, [esp + 8]
	mov ebx, [eax + list.next]

	push eax
	call free
	add esp, 4

	mov eax, ebx

	pop ebx
	ret

;; list* get_node()
;; Allocates the new node
get_node:
	mov eax, list_size
	push eax

	call malloc

	add esp, 4
	ret