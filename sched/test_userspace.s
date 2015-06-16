%macro PRINT 1
	mov eax, 2
	mov edi, 2
	mov esi, %1
	int 0x80
%endmacro
%macro WRITE 3
	mov edi, %1
	mov esi, %2
	mov ebx, %3
	mov eax, 4
	int 0x80
%endmacro
%macro READ 3
	mov edi, %1
	mov esi, %2
	mov ebx, %3
	mov eax, 3
	int 0x80
%endmacro
global test_userspace
test_userspace:
	PRINT .message
	PRINT .creating_pipe
	mov eax, 42
	sub esp, 8
	mov edi, esp
	int 0x80
	PRINT .pipe_created
	WRITE [esp + 4], .output_mess, .output_mess_len
	READ [esp], .buffer, .output_mess_len
	PRINT .output_mess
	PRINT .buffer
	add esp, 8
	ret
	.message: db 'Hello from test_userspace', 10, 0
	.creating_pipe: db 'Creating pipe', 10, 0
	.pipe_created: db 'Pipe created', 10, 0
	.output_mess: db 'PIPEOKPIPEOKPIPEOK', 10, 0
	.output_mess_len: equ $ - .output_mess
	.buffer: db '                                    '
