struc pipe
.cap: resd 1
.head: resd 1
.tail: resd 1
;;; Next "cap" bytes are the buffer
.start: resd 0
endstruc

section .data
;; TODO: Fix this when adding malloc
no_malloc_storage: resd 10 * 4096
allocated: dd 0

;; TODO: Fix this when adding malloc
;; pipe_t* allocate_pipe(size_t capacity as $ebx)
allocate_pipe:
	mov eax, [allocated]
	add eax, no_malloc_storage
	add [allocated], ebx
	add dword [allocated], pipe_size
	ret

global pipe_new
;;; pipe_t* pipe_new(size_t capacity);
pipe_new:
	push ebx
	mov ebx, [esp + 8]
	;; Creating pipe of size (capacity + 1)
	;; to distinguish full and empty states.
	;; pipe is empty when head == tail
	;; and pipe is full when tail == head - 1
	;; by modulo cap
	inc ebx

	call allocate_pipe
	mov [eax + pipe.cap], ebx
	mov dword [eax + pipe.head], 0
	mov dword [eax + pipe.tail], 0

	pop ebx
	ret

global pipe_free
;;; void pipe_free(pipe_t*);
pipe_free:
       ;; TODO: Free when adding malloc
	ret

;;; int pipe_write(pipe_t*, char*, size_t)
global pipe_write
pipe_write:
	push ebp
	mov ebp, esp

	push ecx
	push ebx
	push edi
	push esi
	push edx

	mov edx, [ebp + 16]
	mov esi, [ebp + 12]
	add edx, esi
	mov edi, [ebp + 8]
	mov ecx, [edi + pipe.tail]
	mov ebx, [edi + pipe.head]
	add ebx, [edi + pipe.cap]
	dec ebx
	cmp ebx, [edi + pipe.cap]
	jb .ebx_ok
	sub ebx, [edi + pipe.cap]
	.ebx_ok:

	;; ecx = tail
	;; ebx = (head - 1) % cap
	;; esi = start of buffer
	;; edx = end of buffer

	.loop:
	;; ecx = current tail
	;; esi = current symbol ptr

	cmp ecx, ebx
	je .end_loop
	cmp esi, edx
	je .end_loop

	;; ecx != ebx
	;; esi != edx (there are symbols to write)
	mov al, [esi]
	inc esi

	lea ecx, [ecx + edi + pipe.start]
	;; ecx = pointer to write
	mov [ecx], al
	sub ecx, edi
	sub ecx, pipe.start
	inc ecx
	cmp ecx, [edi + pipe.cap]
	jne .no_overflow
	;; ecx == pipe size
	mov ecx, 0
	.no_overflow:
	;; 0 <= ecx < pipe size - current tail
	jmp .loop
	.end_loop:

	;; ecx = new tail
	;; esi - [ebp + 12] = how many bytes had been read
	mov [edi + pipe.tail], ecx
	mov eax, esi
	sub eax, [ebp + 12]

	pop edx
	pop esi
	pop edi
	pop ebx
	pop ecx

	pop ebp
	ret

;;; int pipe_read(pipe_t*, char*, size_t)
global pipe_read
pipe_read:
	push ebp
	mov ebp, esp

	push edi
	push esi
	push edx
	push ecx
	push ebx

	mov edi, [ebp + 8]
	mov esi, [ebp + 12]
	mov edx, [ebp + 16]
	add edx, esi
	mov ecx, [edi + pipe.tail]
	mov ebx, [edi + pipe.head]

	;; esi = start of buffer
	;; edx = end of buffer
	;; ecx = tail
	;; ebx = current head

	.loop:
	;; ebx = current head
	;; esi = current symbol ptr

	cmp ebx, ecx
	je .end_loop
	cmp esi, edx
	je .end_loop

	;; tail != head (pipe is not empty)
	;; esi != edx (buffer is not full)
	lea ebx, [ebx + edi + pipe.start]
	;; ebx = pointer to next symbol
	mov al, [ebx]
	mov [esi], al
	inc esi
	sub ebx, edi
	sub ebx, pipe.start
	inc ebx

	cmp ebx, [edi + pipe.cap]
	jne .no_overflow
	mov ebx, 0

	.no_overflow:
	;; 0 <= ebx < pipe size
	;; ebx = ptr to next symbol
	;; esi = ptr to next symbol

	jmp .loop
	.end_loop:

	;; ebx = new head
	;; result = esi - [ebp + 12]
	mov [edi + pipe.head], ebx
	mov eax, esi
	sub eax, [ebp + 12]

	pop ebx
	pop ecx
	pop edx
	pop esi
	pop edi

	pop ebp
	ret

;;; size_t pipe_read_available(pipe_t*)
global pipe_read_available
pipe_read_available:
	push ebp
	mov ebp, esp

	push ebx
	push ecx

	mov eax, [ebp + 8]
	mov ebx, [eax + pipe.head]
	mov ecx, [eax + pipe.tail]
	mov eax, [eax + pipe.cap]

	cmp ebx, ecx
	ja .reverse
	;; in this branch pipe looks like |___h----t___|
	;; so available space is (t - h)
	mov eax, ecx
	sub eax, ebx
	jmp .exit

	.reverse:
	;; here pipe looks like |---t____h---|
	;; so available space is (size - h + t)
	sub eax, ebx
	add eax, ecx

	.exit:
	pop ecx
	pop ebx

	pop ebp
	ret

;;; size_t pipe_write_available(pipe_t*)
global pipe_write_available
pipe_write_available:
	push ebp
	mov ebp, esp

	push ebx
	push ecx

	mov eax, [ebp + 8]
	mov ebx, [eax + pipe.head]
	mov ecx, [eax + pipe.tail]
	mov eax, [eax + pipe.cap]

	cmp ebx, ecx
	ja .reverse
	;; in this branch pipe looks like |___h----t___|
	;; so available space is (cap - t - 1 + h)
	sub eax, ecx
	dec eax
	add eax, ebx
	jmp .exit

	.reverse:
	;; here pipe looks like |---t____h---|
	;; so available space is (h - t)
	mov eax, ebx
	sub eax, ecx

	.exit:
	pop ecx
	pop ebx

	pop ebp
	ret
