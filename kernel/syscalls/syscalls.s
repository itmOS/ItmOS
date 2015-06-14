%include "interrupts/interrupts.inc"
%include "interrupts/interrupts_macro.inc"
%include "kernel/syscalls/macro.inc"
%include "kernel/io/io.inc"
%include "kernel/io/pipe.inc"

section .text
global init_syscalls
init_syscalls:
	ADD_SYSTEM_FUNCTION 3, read_syscall
	ADD_SYSTEM_FUNCTION 4, write_syscall
	;; ADD_SYSTEM_FUNCTION 6, close_syscall
	ADD_SYSTEM_FUNCTION 42, pipe_syscall
	ret

read_syscall:
	FORWARD_SYSCALL_ARGS io_read, 3
	ret

write_syscall:
	FORWARD_SYSCALL_ARGS io_write, 3
	ret

close_syscall:
	FORWARD_SYSCALL_ARGS io_close, 1
	ret

pipe_syscall:
	FORWARD_SYSCALL_ARGS pipe_fds_new, 1
