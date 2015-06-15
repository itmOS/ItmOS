%macro PRINT 1
	mov eax, 2
	mov edi, 2
	mov esi, %1
	int 0x80
%endmacro
global test_userspace
test_userspace:
	PRINT .message
	PRINT .creating_pipe
	mov eax, 42
	sub esp, 8
	mov edi, [esp]
	int 0x80
	PRINT .pipe_created
	ret
	.message: db 'Hello from test_userspace', 10, 0
	.creating_pipe: db 'Creating pipe', 10, 0
	.pipe_created: db 'Pipe created', 10, 0
