%include "kernel/io/structs.inc"
%include "kernel/io/pipe_pure.inc"
%include "kernel/io/io.inc"
%include "stdlib.inc"
%include "util/macro.inc"
%include "sched/sched.inc"

PIPE_SIZE:	equ 256
struc pipe_obj
.count: resd 1
.read: resd 1
.write: resd 1
.close: resd 1
.pipe: resd 1
.which_end: resd 1
endstruc

section .text

;;; void pipe_obj_new(fd_obj* res[2]);
;;; TODO: Errors handling
global pipe_obj_new
pipe_obj_new:
	push ebp
	mov ebp, esp

	push ebx
	push ecx

	;xchg bx, bx
	CCALL pipe_new, dword PIPE_SIZE
	mov ebx, eax
	xor eax, eax

	mov ecx, [ebp + 8]
	CCALL create_end, ebx, dword PIPE_READER
	mov [ecx], eax
	CCALL create_end, ebx, dword PIPE_WRITER
	mov [ecx + 4], eax

	pop ecx
	pop ebx

	pop ebp
	ret

;;; int pipe_fds_new(int res[2]);
global pipe_fds_new
pipe_fds_new:
	push ebp
	mov ebp, esp

	push ecx
	push ebx

	sub esp, 8

	push esp
	call pipe_obj_new
	add esp, 4

	mov ebx, [esp + 4]
	push ebx
	call add_fd_object
	add esp, 4
	mov ecx, [ebp + 8]
	mov [ecx], eax
	mov ebx, [esp]
	push ebx
	call add_fd_object
	add esp, 4
	mov ecx, [ebp + 8]
	mov [ecx + 4], eax

	xor eax, eax

	add esp, 8

	pop ebx
	pop ecx

	pop ebp
	ret

;;; pipe_obj* create_end(pipe_t* pipe, int which_end)
create_end:
	push ebx

	CCALL malloc, dword pipe_obj_size

	mov dword [eax + pipe_obj.count], 0

	mov dword [eax + pipe_obj.read], pipe_obj_read
	mov dword [eax + pipe_obj.write], pipe_obj_write
	mov dword [eax + pipe_obj.close], pipe_obj_close
	mov ebx, [esp + 8]
	mov [eax + pipe_obj.pipe], ebx
	mov ebx, [esp + 12]
	mov [eax + pipe_obj.which_end], ebx

	pop ebx
	ret

;;; ssize_t pipe_obj_read(fd_obj* this, void* buf, size_t count)
pipe_obj_read:
	push ebp
	mov ebp, esp

	push esi
	push edi
	push ecx
	push ebx

	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ecx, [ebp + 16]
	xor eax, eax
	test ecx, ecx
	;; eax = 0, if ecx = 0 then exit.
	je .exit

	mov ebx, [esi + pipe_obj.pipe]
	CCALL pipe_read, ebx, edi, ecx

	test eax, eax
	;; if eax != 0 then return eax
	;; else return IO_WOULD_BLOCK (because eax = 0 and ecx != 0
	;; => pipe is empty)
	jne .exit
	mov eax, IO_WOULD_BLOCK

	.exit:
	pop ebx
	pop ecx
	pop edi
	pop esi

	pop ebp
	ret

;;; ssize_t pipe_obj_write(fd_obj* this, void* buf, size_t count)
pipe_obj_write:
	push ebp
	mov ebp, esp

	push esi
	push edi
	push ecx
	push ebx

	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ecx, [ebp + 16]
	xor eax, eax
	test ecx, ecx
	;; if eax == 0 then return 0
	je .exit

	mov ebx, [esi + pipe_obj.pipe]
	CCALL pipe_write, ebx, edi, ecx

	test eax, eax
	;; if eax != 0 then return eax
	;; else return IO_WOULD_BLOCK (because eax = 0 and ecx != 0
	;; => pipe is full)
	jne .exit
	mov eax, IO_WOULD_BLOCK

	.exit:
	pop ebx
	pop ecx
	pop edi
	pop esi

	pop ebp
	ret

;;; ssize_t pipe_obj_close(fd_obj* this)
pipe_obj_close:
	mov eax, [esp + 4]
	dec dword [eax]
	cmp dword [eax], 0
	jnz .ret
	CCALL pipe_obj_delete, eax
	.ret:
	xor eax, eax
	ret

;;; TODO: Leaking. Delete the pipe inside object, dont forget the another end
;;; void pipe_obj_delete(pipe_obj*)
pipe_obj_delete:
	jmp free
