section .text

;;; void free(void* addr)
;;; frees memory chunk starting from addr
free:
        ret


;;; void free(void* addr)
;;; frees memory chunk starting from addr in kernel memory
kfree:
        ret
