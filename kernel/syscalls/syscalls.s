%include "interrupts/interrupts.inc"
%include "interrupts/interrupts_macro.inc"
%include "kernel/syscalls/macro.inc"
%include "kernel/io/io.inc"

section .text
global init_syscalls
init_syscalls:
	ADD_SYSTEM_FUNCTION 3, read_syscall
	ADD_SYSTEM_FUNCTION 4, write_syscall
	ADD_SYSTEM_FUNCTION 5, close_syscall
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
