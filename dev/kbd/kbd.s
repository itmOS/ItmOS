%include "tty/tty.inc"
%include "util/macro.inc"

section .text

global get_from_scancode
global buf_putc
global buf_getc
global buf_delc
global buffer
global bufsize
global top
global bottom
        

BUFSIZE         equ      1024

get_from_scancode:
        mov eax, [esp + 4]
        mov cl, al
        and cl, 0x80
        jz .set
        
        xor al, al
        jmp .exit
.set:
        mov al, [scancodes + eax] 
.exit:
        ret

%macro CHECK_BOUNDS 0
        push eax
        push ecx
        push ebx

        mov dword eax, [bottom]
        mov dword ecx, [top]
        ;; Check if any bound equals max size
        cmp eax, BUFSIZE
        jne %%top
        mov eax, 0
%%top:  
        cmp ecx, BUFSIZE
        jne %%exit
        mov ecx, 0

%%exit: 
        mov dword [bottom], eax
        mov dword [top], ecx
        mov dword ebx, [bufsize]

        pop ebx
        pop ecx
        pop eax
%endmacro

buf_putc:
        push ecx
        ;; Check if top and bottom pointers are same
        mov dword ecx, [top]
        cmp dword ecx, [bottom]
        jne .simple

        ;; If so and and buffer is not full
        mov dword ecx, [bufsize]
        cmp ecx, BUFSIZE
        jne .simple

        ;; The top byte will be thrown away so move pointer
        ;; And decrease size
        inc dword [top]
        dec dword [bufsize]
.simple:
        inc dword [bufsize]
        mov dword ecx, [bottom]
        mov byte [buffer + ecx], al
        inc dword [bottom]
        CHECK_BOUNDS
        pop ecx
        ret


buf_delc:
        push ecx
        ;; Check if top and bottom pointers are same
        mov dword ecx, [top]
        cmp dword ecx, [bottom]
        jne .simple

        ;; If so and and buffer is not full
        cmp dword [bufsize], 0
        jne .simple
        pop ecx
        ret
.simple:
        ;; No delete if size zero
        mov ecx, [bufsize]
        test ecx, ecx
        jz .exit
        ;; No delete if last symbol is endl
        mov dword ecx, [bottom]
        test ecx, ecx
        jnz .nzero
        mov ecx, BUFSIZE
.nzero:
        dec ecx
        xor eax, eax
        mov al, [buffer + ecx]
        cmp al, 10
        je .exit
        mov [bottom], ecx
        dec dword [bufsize]
.exit:
        pop ecx
        ret


buf_getc:
        push ecx
        ;; Check if top and bottom pointers are same
        mov dword ecx, [top]
        cmp dword ecx, [bottom]
        jne .simple

        ;; If so and and buffer is not full
        cmp dword [bufsize], 0
        jne .simple
        ;; There is nothing return 0
        xor eax, eax
        pop ecx
        ret
.simple:
        ;; Taking character decreases size
        dec dword [bufsize]
        ;; Get symbol
        mov dword ecx, [top]

        xor eax, eax
        mov al, [buffer + ecx]
        inc dword [top]
        CHECK_BOUNDS
        pop ecx
        ret

align 4
top:
        dd 0
bottom:
        dd 0
bufsize:
        dd 0

        ;; TODO alloc when possible
buffer:     
        times BUFSIZE db 0

putoutstr:
        db "%d %d %d ", 0


scancodes:
	db 0
	db 0                            ; ESC
	db '1','2','3','4','5','6','7','8','9','0', '-', '='
	db 8                            ; BACKSPACE
	db 0                            ; TAB
	db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']'
	db 10                           ;  ENTER
	db 0                            ; CTRL
	db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 59, 39, 96
	db 0                            ; LEFT SHIFT
	db 92, 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', 47
	db 0                            ; RIGHT SHIFT
	db '*'                          ; NUMPAD
	db 0                            ; ALT
	db ' '                          ; SPACE
	db 0                            ; CAPSLOCK
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; F1 - F10
	db 0                            ; NUMLOCK
	db 0                            ; SCROLLLOCK
	db 0                            ; HOME
	db 0
	db 0                            ; PAGE UP
	db '-'                          ; NUMPAD
	db 0, 0
	db 0
	db '+'                          ; NUMPAD
	db 0                            ; END
	db 0
	db 0                            ; PAGE DOWN
	db 0                            ; INS
	db 0                            ; DEL
	db 0                            ; SYS RQ
	db 0
	db 0, 0                         ; F11 - F12
	db 0
	db 0, 0, 0                      ; F13 - F15
	db 0, 0, 0, 0, 0, 0, 0, 0, 0    ; F16 - F24
	db 0, 0, 0, 0, 0, 0, 0, 0
