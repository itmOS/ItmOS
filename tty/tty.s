section .text

%include "boot/boot.inc"

global tty_clear
global tty_puts
global tty_putc
global tty_delc
global tty_endl
global tty_set_style
global tty_save_style
global tty_restore_style
global tty_printf
global tty_cdecl_puts

;;; Clear the screen
tty_clear:
	push edi
	push ecx

	mov edi, video_start
	mov ecx, video_memory_size_d
	xor eax, eax
	repe stosd
	pop ecx
	pop edi
	ret

extern sprintf
tty_printf:
	push ebp
	mov ebp, esp
	push esi

	sub esp, screen_width
	lea esi, [ebp + 12]
	push esi
	sub esi, 4
	mov esi, [esi]
	push esi
	lea esi, [esp + 8]
	push esi
	call sprintf
	add esp, 12
	mov esi, esp
	call tty_puts
	
	mov esi, [esp + screen_width]
	mov esp, ebp
	pop ebp
	ret

;;; Set text style
;;; al = (background_color << 4) + foreground_color
;;; where background_color from 0 to 15
;;; and   foreground_color from 0 to 15
tty_set_style:
	push ebx
	xor ebx, ebx
	mov bl, byte [cur_text_style]
	mov byte [ebx + text_style], al
	pop ebx
	ret

;;; Save the current terminal text style
;;; (pushes it on the stack).
;;; Can be restored later via tty_restore_style.
tty_save_style:
	push eax
	push ebx
	xor ebx, ebx
	mov bl, byte [cur_text_style]
	mov al, byte [ebx + text_style]
	inc byte [cur_text_style]
	mov byte [ebx + text_style + 1], al
	pop ebx
	pop eax
	ret

;;; Restore the last saved terminal text style,
;;; removes it from the stack.
tty_restore_style:
	dec byte [cur_text_style]
	ret

;;; Put string to the cursor position
;;; esi -- zero-ended string
tty_puts:
	push eax
	push esi

	.loop:
	mov al, [esi]
	test al, al
	jz .end_loop
	call tty_putc
	inc esi
	jmp .loop
	.end_loop

	pop esi
	pop eax
	ret

check_for_overflow:
	cmp word [cursor_pos], screen_size
	jl .return
	push esi
	push edi
	push eax
	push ecx

	mov edi, video_start
	mov esi, video_start + screen_width * 2
	mov ecx, screen_size - screen_width
	repe movsw
	mov edi, video_start + (screen_size - screen_width) * 2
	xor ax, ax
	mov ecx, screen_width
	repe stosw
	sub word [cursor_pos], screen_width

	pop ecx
	pop eax
	pop edi
	pop esi
	.return:
	ret

;;; Put char to the cursor position
;;; al -- character. Character with code 10 means line end.
tty_putc:
	cmp al, 10
	jne .put_char
	call tty_endl
	ret
.put_char:
	push ecx
	push ebx
	push eax
	mov ebx, [cursor_pos]
	xor ecx, ecx
	mov cl, byte [cur_text_style]
	mov ah, byte [ecx + text_style]
	mov [ebx + ebx + video_start], ax
	inc word [cursor_pos]
	call check_for_overflow
	inc dword [from_endl]

	pop eax
	pop ebx
	pop ecx
	ret

;;; Remove last character if it exists and is not endl
tty_delc:
        push eax
        push ebx
        push ecx
        ;; Check if not the beginning
        xor ebx, ebx
        mov ebx, [cursor_pos]
        test ebx, ebx
        jz .exit

        mov eax, [from_endl]
        test eax, eax
        jz .exit

        ;; Set previous symbol to '\0'
        dec ebx
        xor eax, eax
        mov [ebx + ebx + video_start], ax
        dec word [cursor_pos]
        dec dword [from_endl]
.exit:
        pop ecx
        pop ebx
        pop eax
        ret

;;; Change cursor position to the start of the next line.
tty_endl:
	push eax
	push edx
	push ecx

	xor dx, dx
	mov ax, [cursor_pos]
	mov cx, screen_width
	div cx
	sub [cursor_pos], dx
	add word [cursor_pos], screen_width
	call check_for_overflow
	mov dword [from_endl], 0

	pop ecx
	pop edx
	pop eax
	ret

;;; Address of the start of the video memory
video_start: equ 0xB8000 ;; (KERNEL_VMA + 0xB8000)
screen_width: equ 80
screen_height: equ 25
screen_size: equ screen_width * screen_height
video_memory_size_d: equ screen_size / 2

section .data
text_style: 
	db 0x07
	times 63 db 0
text_style_bottom:
cur_text_style: db 0

align 4
cursor_pos: dd 0
from_endl:   dd 0
