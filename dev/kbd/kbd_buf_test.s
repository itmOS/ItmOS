%include "util/test/test.inc"
%include "dev/kbd/kbd.inc"
%include "tty/tty.inc"

global kbd_register_tests
extern buffer
extern bufsize
extern top
extern bottom
        
kbd_buf_test:
        KBDBUF_PUTC 'a'
        KBDBUF_GETC
	cmp byte al, 'a'
        je .success
        mov dword eax, -1
        ret
.success:
        mov dword eax, 0
        ret
kbd_buf_test_size:
        KBDBUF_PUTC 'a'
        cmp dword [bufsize], 1
        je .success
        KBDBUF_GETC
        mov dword eax, -1
        ret
.success:
        KBDBUF_GETC
        mov dword eax, 0
        ret       

kbd_buf_test_hard:
        mov dword ecx, 1024
.loop:
        test ecx, ecx
        jz .continue
        KBDBUF_PUTC 'a'
        dec ecx
        jmp .loop
.continue:
        KBDBUF_PUTC 't'

        mov dword ecx, 1024
.loop2:
        test ecx, ecx
        jz .continue2
        KBDBUF_GETC
        dec ecx
        jmp .loop2
.continue2:
        mov dword ecx, 1024
.loop3:
        test ecx, ecx
        jz .continue3
        KBDBUF_PUTC 'o'
        dec ecx
        jmp .loop3
.continue3:
 	mov dword ecx, 1024
        KBDBUF_PUTC 'r'
.loop4:
        test ecx, ecx
        jz .continue4
        KBDBUF_GETC
        dec ecx
        jmp .loop4
.continue4:
	cmp byte al, 'r'
        je .success
        mov dword eax, -1
        ret
.success:
        mov dword eax, 0
        ret       

kbd_register_tests:
        TEST_REGISTER_SINGLE test1, kbd_buf_test
        TEST_REGISTER_SINGLE test2, kbd_buf_test_size
        TEST_REGISTER_SINGLE test3, kbd_buf_test_hard
        ret

test1:
       db "DEV/KBD: simple", 0
test2:
       db "DEV/KBD: simple size", 0
test3:
       db "DEV/KBD: hard", 0
