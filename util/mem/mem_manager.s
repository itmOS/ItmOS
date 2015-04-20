section .text

extern memory_map

init_mem_manager:

        ret

;;; Takes amount of pages and return address of memory block if given size
;;; Returns -1 if amount of free memory is less
;;; Return -1 if there is no coherent block of input size
;;; If memory needed can be divided use get_one_page
get_pages:
        ret

;;; put_pages(address, size)
;;; Sets given amount of pages beginning from given address free
put_pages:
        ret

;;; Return address to one page of physical memory
;;; Returns -1 if there are no pages
get_one_page:
        ret

;;; put_one_page(address)
;;; Sets page from given address free
put_one_page:
        ret


temp_map_page:
        ret

map_pages:
        ret

        
get_page_info:  
        ret

;;; Address of the first block
begin_page:     dw 0
;;; Amount of free pages
page_count:     dw 0
