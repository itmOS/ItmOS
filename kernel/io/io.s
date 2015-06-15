%include "kernel/io/structs.inc"
%include "util/hash/hash_table.inc"
%include "util/list/list.inc"
%include "sched/sched.inc"
%include "util/macro.inc"

;;; Hash table of the pending processes
;;; hash_table<fd_obj*, pid_t>
pending_table: resd 1

global io_initialize
io_initialize:
	call ht_empty
	mov [pending_table], eax
	ret

global io_notify_available
io_notify_available:
	push ebp
	mov ebp, esp

	push ebx
	push ecx
	push esi
	push edi

	mov ecx, [pending_table]
	mov ebx, [ebp + 8]
	CCALL ht_get, ecx, ebx
	mov esi, eax

	.loop:
	test esi, esi
	jz .end_loop

	mov edi, [esi + list.data]
	push edi
	call unblock_pid

	push ebx
	push ecx
	call ht_remove
	add esp, 4 * 3

	CCALL list_pop, esi
	mov esi, eax

	jmp .loop
	.end_loop:

	pop edi
	pop esi
	pop ecx
	pop ebx

	pop ebp
	ret

global io_read
;;; int io_read(int fd, void* buf, size_t count)
io_read:
	push ebp
	mov ebp, esp

	push esi
	push edi
	push ebx
	push ecx

	.restart:
	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ebx, [ebp + 16]

	CCALL get_fd_object, esi
	mov esi, eax
	mov ecx, [esi + fd_obj.read]
	;; Calling fd_obj->read(this, buffer, count)
	CCALL ecx, esi, edi, ebx

	cmp eax, IO_WOULD_BLOCK
	jne .exit
	call stop_current_pid
	jmp .restart

	.exit:
	pop ecx
	pop ebx
	pop edi
	pop esi

	pop ebp
	ret

global io_write
;;; int io_write(int fd, void* buf, size_t count)
io_write:
	push ebp
	mov ebp, esp

	push esi
	push edi
	push ebx
	push ecx

	.restart:
	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ebx, [ebp + 16]

	CCALL get_fd_object, esi
	mov esi, eax
	mov ecx, [esi + fd_obj.write]
	;; Calling fd_obj->write(this, buffer, count)
	CCALL ecx, esi, edi, ebx

	cmp eax, IO_WOULD_BLOCK
	jne .exit
	call stop_current_pid
	jmp .restart

	.exit:
	pop ecx
	pop ebx
	pop edi
	pop esi

	pop ebp
	ret


global io_close
;;; int io_close(int fd)
io_close:
	push ebp
	mov ebp, esp

	push esi
	push ecx

	.restart:
	mov esi, [ebp + 8]

	CCALL get_fd_object, esi
	mov esi, eax
	mov ecx, [esi + fd_obj.close]
	;; Calling fd_obj->close(this)
	CCALL ecx, esi

	cmp eax, IO_WOULD_BLOCK
	jne .exit
	call stop_current_pid
	jmp .restart

	.exit:
	pop ecx
	pop esi

	pop ebp
	ret

;;; Block the current pid, takes the current fd_obj as $esi
stop_current_pid:
	push ecx

	call current_pid
	mov ecx, [pending_table]
	CCALL ht_add, ecx, esi, eax
	call suspend_syscall

	pop ecx
	ret
