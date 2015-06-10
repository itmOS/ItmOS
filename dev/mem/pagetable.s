section .text

%include "tty/tty.inc"

;;; Creates new page table with mapped last 1 GB same as current
;;; void* new_page_table(void* table);
new_page_table:
        ret

;;; Duplicates page table(physical address): maps first 3GB to new pages and copies data; maps last 1 GB to same pages
;;; void* dup_page_table(void* table);
duplicate_page_table:
        ret

;;; Frees given page table(physical address): unmaps all virtual pages except last 1 GB
;;; void free_page_table(void*);
free_page_table:
        ret

;;; Copies data of src physical page to dst physical page
;;; void memcpy(void* src, void* dst);
memcpy_page:
        ret
