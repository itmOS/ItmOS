section .text

global get_from_scancode

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
