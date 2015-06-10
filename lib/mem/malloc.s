 section .text


;;; void* malloc(int len)
;;; returns pointer to memory chunk of len bytes
malloc:
        ret


;;; void* kmalloc(int len)
;;; returns pointer to memory chunk of len bytes in kernel memory
kmalloc:
        ret
