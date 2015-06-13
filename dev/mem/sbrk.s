section .text

%include "dev/mem/sbrk.inc"

extern get_physaddr
extern get_pages
extern put_pages
extern map_page
extern unmap_page

global sbrk


HEAP_BEGIN      equ     0xc0400000
HEAP_END        equ     0xFFFFDFFF
FLAG            equ     0x3

;;; Increases program break(end of data segment) with incr bytes
;;; int sbrk(int incr);
sbrk:
        mov eax, [esp + 4]
        SBRK eax, HEAP_BEGIN, HEAP_END, FLAG
