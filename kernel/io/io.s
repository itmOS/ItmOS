%include "kernel/io/structs.inc"
%include "sched/sched.inc"
%include "util/macro.inc"

global io_notify_available
io_notify_available:
	;; TODO: Add notification when the scheduler
	;; will support blocked processes
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
	call suspend_syscall
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
	call suspend_syscall
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
	call suspend_syscall
	jmp .restart

	.exit:
	pop ecx
	pop esi

	pop ebp
	ret
