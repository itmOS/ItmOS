global read
read:
	mov eax, 3
	mov edi, [esp + 4]
	mov esi, [esp + 8]
	mov ebx, [esp + 12]
	int 0x80
	ret

global write
write:
	mov eax, 4
	mov edi, [esp + 4]
	mov esi, [esp + 8]
	mov ebx, [esp + 12]
	int 0x80
	ret

global pipe
pipe:
	mov eax, 42
	mov edi, [esp + 4]
	int 0x80
	ret

;;; TODO: Remove this as soon as posible
global write_err
write_err:
	mov eax, 2
	mov edi, 2
	mov esi, [esp + 4]
	int 0x80
	ret
