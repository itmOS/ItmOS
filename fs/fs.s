;; Dummy non-working implementation of the FAT16 FS

;; int fat_open_ro(char* path)
;; gets the path of a file and returns an unique id to read it (or -1 if not found)
fat_open:
    mov eax, -1
    ret


;; ssize_t fat_read(int fid, size_t offset, void* buf, size_t count)
;; tries to read count bytes from the file with the given id at the given offset
;; and returns the number of bytes read
fat_read:
    xor eax, eax
    ret
;; ssize_t fat_write(int fid, size_t offset, void* buf, size_t count)
;; tries to write count bytes to the file with the given id at the given offset
;; and returns the number of bytes written
fat_write:
    xor eax, eax
    ret
