section .text

;;; Changes programs data break(end of data segment) to addr
;;; int brk(void* addr);
brk:
        ret

;;; Changes programs data break(end of data segment) to addr for kernel memory
;;; int kbrk(void* addr);
kbrk:
        ret
