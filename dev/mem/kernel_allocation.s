section .text

;;; void* kmalloc(int len)
;;; returns pointer to memory chunk of len bytes in kernel memory
kmalloc:
        ret

;;; void free(void* addr)
;;; frees memory chunk starting from addr in kernel memory
kfree:
        ret
