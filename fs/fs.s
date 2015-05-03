;;; Dummy, non-working implementation of the FAT16 FS without long names

%include "ata/ata.inc"
%include "util/log/log.inc"

global get_bootrecord
global fat_init
global fat_read

%macro PRINT_NUM 1
    push %1
    push format
    call tty_printf
    add esp, 4
    pop %1
%endmacro
struc boot_record
    .bootjmp:             resb 3
    .oem_name:            resb 8
    .bytes_per_sector:    resw 1
    .sectors_per_cluster: resb 1
    .sectors_reserved:    resw 1
    .fat_copies:          resb 1
    .root_entries:        resw 1
    .sectors_total:       resw 1      ; used if the volume size is not bigger than 32M
    .media_type:          resb 1
    .sectors_per_fat:     resw 1
    .sectors_per_track:   resw 1
    .head_side_count:     resw 1
    .sectors_hidden:      resd 1
    .sectors_total_32:    resd 1      ; used if the volume size is bigger than 32M
    .partition_number:    resw 1
    .extended_signature:  resb 1
    .serial_number:       resd 1
    .volume_name:         resb 11
    .fat_name:            resb 8
    .executable_codes:    resb 448
    .marker:              resb 2      ; 0x55AA
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
    .start_high:  resw 1 ;; the high 16 bits of the first cluster
                         ;; supposed to be 0 for FAT16
    .modify_time: resw 1
    .modify_date: resw 1
    .start:       resw 1
    .file_size:   resd 1
endstruc

section .rodata
    format: db "n: %d", 10, 0
    endl: db 10, 0
    fat_identify_format: db "bytes per sector: %d", 10, "sectors per cluster: %d", 10, "sectors reserved: %d", 10, "root entries: %d", 10, "sectors total: %d", 10, "copies of FAT: %d", 10, "sectors per FAT: %d", 10, 0

section .data
    my_cool_heap: resq 8192
    fat: resq 400*512
    bootrecord: resb boot_record_size
    dirtable: resq 32*512 ; hz if it’s enough
    dirtable_offset: resq 1


section .text

;;; Just prints some information about the file system
fat_identify:
    xor eax, eax
    mov ax, [bootrecord + boot_record.sectors_per_fat]
    push eax

    xor eax, eax
    mov al, [bootrecord + boot_record.fat_copies]
    push eax

    xor eax, eax
    mov ax, [bootrecord + boot_record.sectors_total]
    push eax

    xor eax, eax
    mov ax, [bootrecord + boot_record.root_entries]
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
    add esp, 32
    ret

;;; void fat_init();
;;; Initializes the file system
fat_init:
    ATA_INSEG 0, 1, bootrecord  ; load the boot record
    call fat_identify

    xor eax, eax
    mov ax, [bootrecord + boot_record.sectors_per_fat]
    xor ecx, ecx
    mov cl, [bootrecord + boot_record.fat_copies]
    mul ecx                     ; eax := copies_of_fat * sectors_per_fat
    xor ecx, ecx
    mov cx, [bootrecord + boot_record.sectors_reserved]
    add eax, ecx                ; eax += sectors_reserved
    ; eax is now the directory table offset
    mov [dirtable_offset], eax

    ; load the directory table
    ATA_INSEG eax, 32, dirtable  ; not sure if 32 is the right number, but seems so

    xor esi, esi
    mov si, [bootrecord + boot_record.sectors_reserved]
    xor edx, edx
    mov dx, [bootrecord + boot_record.sectors_per_fat]
    ;load the FAT
    ATA_INSEG esi, edx, fat

    ; write some info about the first file
    TTY_PUTS dirtable + file_entry.name
    mov eax, [dirtable + file_entry.file_size]
    PRINT_NUM eax

    ; and the second one
    TTY_PUTS dirtable + file_entry.name + file_entry_size
    mov eax, [dirtable + file_entry.file_size + file_entry_size]
    PRINT_NUM eax


    push 1488
    push 1488
    push my_cool_heap
    push dword 0
    call fat_read
    add esp, 16
    TTY_PUTS my_cool_heap

    ret

;;; void* get_bootrecord()
;;; For debug purposes only
get_bootrecord:
    mov eax, bootrecord
    ret

;;; int fat_open_ro(char* path)
;;; Gets the path of a file and returns a unique id to read it (or -1 if not found)
fat_open:
    mov eax, -1
    ret

;;; size_t fat_file_size(int fid)
;;; Returns the size (in bytes) of the given file
fat_file_size:
    mov edx, [esp + 4]
    mov eax, [edx + file_entry.file_size]
    ret

;;; ssize_t fat_read(int fid, void* dest, int offset, int count)
;;; Tries to read count bytes from the file with the given id at the given offset
;;; and returns the number of bytes read

;;; ^ lie, pizdezh and provocation
;;; offset and count are currently ignored
;;; it reads the whole file into the buffer (and also some trailing bytes till the end of the cluster)
;;; also, it always returns zero
fat_read:
    push ebp
    mov  ebp, esp
    push ebx
    push edi
    push esi
    mov  ebx, 512
    xor  ecx, ecx
    xor  edx, edx
    mov  edi, [ebp + 12]
    mov  ecx, [ebp + 8]
    xor  esi, esi
    mov  si,  [dirtable + file_entry.start] ; the first cluster of the file
    add  esi, ecx
    xor  ecx, ecx
    mov  cl,  [bootrecord + boot_record.sectors_per_cluster]
    .loop
        cmp  esi, 0FFFFh
        je  .end

        mov  eax, esi
        sub  eax, 2
        mul  ecx
        add  eax, 32
        add  eax, [dirtable_offset]

        push ecx
        push edi
        ATA_INSEG eax, ecx, edi
        pop  edi
        pop  ecx
        mov  eax, ecx
        mul  ebx
        add  edi, eax
        xor  edx, edx
        mov  dx, si
        shl  edx, 1
        mov  si, [fat + edx]
        push ecx
        PRINT_NUM esi
        pop  ecx
        jmp  .loop
    .end
    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

;;; ssize_t fat_write(int fid, size_t offset, void* buf, size_t count)
;;; Tries to write count bytes to the file with the given id at the given offset
;;; and returns the number of bytes written
fat_write:
    xor eax, eax
    ret
