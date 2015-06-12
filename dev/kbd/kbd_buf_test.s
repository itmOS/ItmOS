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


kbd_buf_test_del:
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
        KBDBUF_DELC
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

kbd_buf_test_del2:
        KBDBUF_PUTC 'r'
        KBDBUF_DELC
        KBDBUF_GETC
	cmp byte al, 0
        je .success
        mov dword eax, -1
        ret
.success:
        mov dword eax, 0
        ret 

kbd_buf_test_del3:
        KBDBUF_PUTC 'r'
        KBDBUF_PUTC 'r'
        KBDBUF_PUTC 'r'
        KBDBUF_PUTC 'r'
        KBDBUF_DELC
        KBDBUF_DELC
        KBDBUF_DELC
        KBDBUF_DELC
        KBDBUF_DELC
        KBDBUF_GETC
	cmp byte al, 0
        je .success
        mov dword eax, -1
        ret
.success:
        mov dword eax, 0
        ret 

kbd_buf_test_del4:
        KBDBUF_PUTC 10
        KBDBUF_DELC
        KBDBUF_GETC
	cmp byte al, 10
        je .success
        KBDBUF_GETC
        mov dword eax, -1
        ret
.success:
        KBDBUF_GETC
        mov dword eax, 0
        ret 



kbd_register_tests:
        TEST_REGISTER_SINGLE test1, kbd_buf_test
        TEST_REGISTER_SINGLE test2, kbd_buf_test_size
        TEST_REGISTER_SINGLE test3, kbd_buf_test_hard
        TEST_REGISTER_SINGLE test4, kbd_buf_test_del
        TEST_REGISTER_SINGLE test5, kbd_buf_test_del2
        TEST_REGISTER_SINGLE test6, kbd_buf_test_del3
        TEST_REGISTER_SINGLE test7, kbd_buf_test_del4
        ret

test1:
       db "DEV/KBD: simple", 0
test2:
       db "DEV/KBD: simple size", 0
test3:
       db "DEV/KBD: hard", 0
test4:
       db "DEV/KBD: del", 0
test5:
       db "DEV/KBD: del 2", 0
test6:
       db "DEV/KBD: del 3", 0
test7:
       db "DEV/KBD: del 3", 0
