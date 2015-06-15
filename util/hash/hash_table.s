%include "stdlib.inc"
%include "util/list/list.inc"
%include "util/macro.inc"

TABLE_SIZE: equ (1 << 17)
HASH_MASK: equ (TABLE_SIZE - 1)

struc entry
.key: resd 1
.value: resd 1
endstruc

struc hash_table
;;; list<entry>* data[TABLE_SIZE]
.data: resd TABLE_SIZE
endstruc

;;; GET_HASH dst, src
%macro GET_HASH 2
	mov %1, %2
	and %1, HASH_MASK
%endmacro

;;; MAKE_ENTRY dst, key, value
%macro MAKE_ENTRY 3
	push eax
	push ecx

	push entry_size
	call malloc
	add esp, 4

	mov ecx, %2
	mov [eax + entry.key], ecx
	mov ecx, %3
	mov [eax + entry.value], ecx

	mov %1, eax

	pop ecx
	pop eax
%endmacro

global ht_empty
;;; hash_table* ht_empty()
ht_empty:
	push edi
	push ecx

	CCALL malloc, dword hash_table_size

	push eax
	;; Fill the table with zeros
	mov edi, eax
	xor eax, eax
	mov ecx, hash_table_size
	repe stosb
	pop eax

	pop ecx
	pop edi
	ret

;;; void ht_free(hash_table*)
;;; TODO: Free all nodes too
global ht_free
ht_free:
	jmp free

;;; list* ht_get(hash_table* table, void* key)
global ht_get
ht_get:
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	push edi

	mov edi, [ebp + 12]
	GET_HASH ebx, edi
	mov ecx, [ebp + 8]

	;; ebx = key hash
	mov ecx, [ecx + ebx * 4]
	;; ecx = list of elements with hash ebx
	;; edi = key

	xor ebx, ebx
	;; ebx = empty list
	.loop:
	test ecx, ecx
	jz .end_loop

	CCALL list_head, ecx
	;; eax : entry* = current entry
	cmp [eax + entry.key], edi
	jne .continue
	;; eax->key = edi, so we should add this value to the answer

	mov eax, [eax + entry.value]
	CCALL list_push, ebx, eax
	mov ebx, eax

	.continue:

	CCALL list_tail, ecx
	mov ecx, eax
	;; ebx = current list of answers
	;; ecx = current list of entries
	;; edi = key
	jmp .loop
	.end_loop:

	mov eax, ebx

	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret

;;; void ht_remove(hash_table* table, void* key, void* value)
global ht_remove
ht_remove:
	push ebp
	mov ebp, esp

	push ebx
	push ecx
	push edi
	push esi
	push edx

	mov edi, [ebp + 12]
	mov esi, [ebp + 16]
	GET_HASH edx, edi
	mov ecx, [ebp + 8]

	;; edx = key hash
	mov ecx, [ecx + edx * 4]
	;; ecx = list of elements with hash ebx
	;; edx = key hash
	;; edi = key
	;; esi = value

	xor ebx, ebx
	;; ebx = empty list

	.loop:
	;; ecx = current node in the list
	;; ebx = last node in the list
	test ecx, ecx
	jz .end_loop

	CCALL list_head, ecx
	;; eax : entry* = current entry
	cmp [eax + entry.key], edi
	jne .continue
	;; eax->key = edi, so we should check if eax->value = esi
	;; if so, we should remove the current entry and exit
	;; otherwise we should continue searching
	cmp [eax + entry.value], esi
	jne .continue

	;; Removing current entry
	CCALL list_pop, ecx
	mov ecx, eax
	test ebx, ebx
	jz .set_start

	mov [ebx + list.next], ecx

	jmp .end_loop
	.set_start:
	mov eax, [ebp + 8]
	;; Set new start for the current hash
	mov [eax + edx * 4], ecx

	.continue:
	mov ebx, ecx
	CCALL list_tail, ecx
	mov ecx, eax
	;; ecx = current list of entries
	;; ecx = last node in the list
	;; edi = key
	jmp .loop
	.end_loop:

	xchg bx, bx

	pop edx
	pop esi
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret

;;; void ht_add(hash_table* table, void* key, void* value)
global ht_add
ht_add:
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	push edi
	push esi

	mov edi, [ebp + 12]
	mov esi, [ebp + 16]
	GET_HASH ebx, edi
	mov ecx, [ebp + 8]

	;; ebx = key hash
	mov ecx, [ecx + ebx * 4]
	;; ecx = list of elements with hash ebx
	;; edi = key
	;; esi = value

	.loop:
	test ecx, ecx
	jz .end_loop

	CCALL list_head, ecx
	;; eax : entry* = current entry
	cmp [eax + entry.key], edi
	jne .continue
	;; eax->key = edi, so we should check if eax->value = esi
	;; if so, table already contains this value
	;; so we can break, otherwise we should continue searching
	cmp [eax + entry.value], esi
	je .return

	.continue:
	CCALL list_tail, ecx
	mov ecx, eax
	;; ecx = current list of entries
	;; edi = key
	jmp .loop
	.end_loop:

	;; We had not found this value in the hash_table
	mov ecx, [ebp + 8]
	mov ecx, [ecx + ebx * 4]
	;; ecx is list of values for this hash
	MAKE_ENTRY edi, [ebp + 12], [ebp + 16]
	CCALL list_push, ecx, edi
	mov ecx, [ebp + 8]
	mov [ecx + ebx * 4], eax

	.return:

	pop esi
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret
