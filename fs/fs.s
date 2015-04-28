;; Dummy non-working implementation of the FAT16 FS

%include "ata/ata.inc"
%include "util/log/log.inc"

global get_bootrecord
global fat_init

struc boot_record
    .bootjmp:             resb 3
    .oem_name:            resb 8
    .bytes_per_sector:    resw 1
    .sectors_per_cluster: resb 1
    .sectors_reserved:    resw 1
    .fat_copies:          resb 1
    .root_entries:        resw 1
    .sectors_total:       resw 1
    .media_type:          resb 1
    .sectors_per_fat:     resw 1
    .sectors_per_track:   resw 1
    .head_side_count:     resw 1
    .sectors_hidden:      resd 1
    .sectors_total_32:    resd 1
    .partition_number:    resw 1
    .extended_signature:  resb 1
    .serial_number:       resd 1
    .volume_name:         resb 11
    .fat_name:            resb 8
    .executable_codes:    resb 448
    .marker:              resb 2 ; 0x55AA
endstruc


struc file_entry
    .name:        resb 8
    .ext:         resb 3
    .attr:        resb 1
    .nt_reserved: resb 1 ; reserved for use by Windows NT
    .create_dec:  resb 1 ; creation time in tenths of a second
    .create_time: resw 1
    .create_date: resw 1
    .access_date: resw 1
    .start_high:  resw 1 ; the high 16 bits of the first cluster
                         ; supposed to be 0 for FAT16
    .modify_time: resw 1
    .modify_date: resw 1
    .start:       resw 1
    .file_size:   resd 1
endstruc

section .rodata
    format: db "n: %d", 10, 0
    fat_identify_format: db "bytes per sector: %d; per cluster: %d; reserved: %d; copies: %d; sectors per fat: %d", 10, 0

section .data
    ;fat: dq 40*512
    bootrecord: dq 512
    dirtable: dq 512 ; hz if it’s enough


section .text
fat_identify:

    xor eax, eax
    mov ax, [bootrecord + boot_record.sectors_per_fat]
    push eax
    push eax

    xor eax, eax
    mov al, [bootrecord + boot_record.fat_copies]
    push eax

    xor eax, eax
    mov ax, [bootrecord + boot_record.sectors_reserved]
    push eax

    xor eax, eax
    mov al, [bootrecord + boot_record.sectors_per_cluster]
    push eax

    xor eax, eax
    mov ax, [bootrecord + boot_record.bytes_per_sector]
    push eax
    push fat_identify_format
    call tty_printf
    add esp, 28
    ret

;; void fat_init();
;; initializes the file system
fat_init:
    ATA_INSEG 0, 1, bootrecord
    call fat_identify

    xor eax, eax
    mov ax, [bootrecord + boot_record.sectors_per_fat]
    xor ecx, ecx
    mov cl, [bootrecord + boot_record.fat_copies]
    mul ecx                     ; eax := copies_of_fat * sectors_per_fat
    xor ecx, ecx
    mov cx, [bootrecord + boot_record.sectors_reserved]
    add eax, ecx                ; eax += sectors_reserved
    xor ecx, ecx
    mov cx, [bootrecord + boot_record.bytes_per_sector]
    mul ecx
    ; eax is now the directory table offset

    push eax
    push format
    call tty_printf
    add esp, 8

    ;ATA_INSEG eax, sectors_per_fat, fat
    ret

;; void* get_bootrecord()
;; for debugging purposes only
get_bootrecord:
    xor eax, eax
    mov eax, bootrecord
    ret


;; int fat_open_ro(char* path)
;; gets the path of a file and returns a unique id to read it (or -1 if not found)
fat_open:
    mov eax, -1
    ret

;; size_t fat_file_size(int fid)
;; returns the size (in bytes) of the given file
fat_file_size:
    xor eax, eax
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
