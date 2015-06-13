;;; Dummy, almost non-working implementation of FAT16 without long file names (LFN)

%include "ata/ata.inc"
%include "util/log/log.inc"

global get_bootrecord
global fat_init
global fat_read

extern i_memcmp
extern malloc

%macro PRINT_NUM 1
    push ecx
    push %1
    push format
    call tty_printf
    add esp, 4
    pop %1
    pop ecx
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


struc fat_fdobject
    .count:    resd 1 ; int count;
    .read:     resd 1 ; int (*read)(fdobj* this, void* buf, int count);
    .write:    resd 1 ; int (*write)(fdobj* this, void* buf, int count);
    .close:    resd 1 ; void (*close)(fdobj* this);

    .fid:      resd 1 ; fid is the number of the file entry in the directory table
    .dirtable: resd 1 ; some int, giving the dirtable (not sure yet about its format). currently not used.
    .offset:   resd 1 ; the offset used for read() and write()
    .flags:    resd 1
endstruc

section .rodata
    format: db "n: %d", 10, 0 ; used for debug output
    endl: db 10, 0
    fat_identify_format: db "bytes per sector: %d", 10, "sectors per cluster: %d", 10, "sectors reserved: %d", 10, "root entries: %d", 10, "sectors total: %d", 10, "copies of FAT: %d", 10, "sectors per FAT: %d", 10, 0

section .bss
    my_cool_heap: resq 8192
    fat: resb 400*512
    bootrecord: resb boot_record_size
    dirtable: resb file_entry_size*512 ; hz if it’s enough
    dirtable_offset: resq 1
    fdobjects: resb 300*fat_fdobject_size
    fdobj_count: resd 1


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


    call new_fat_fdobject
    mov  [eax + fat_fdobject.fid], dword 1
    ;xor  eax, eax
    push 1488 ; count — ignored
    push my_cool_heap ; dest
    push eax
    call [eax + fat_fdobject.read] ; virtual function — where is your C++ now?
    add esp, 12
    TTY_PUTS my_cool_heap

    ret

;;; void* get_bootrecord()
;;; For debug purposes only
get_bootrecord:
    mov eax, bootrecord
    ret

;;; fat_fdobject* new_fat_fdobject();
;;; for internal use only, just creates an fdobject with .count, .read, .write and .close set correctly
new_fat_fdobject:
    mov eax, [fdobj_count]
    mov ecx, fat_fdobject_size
    ;mul ecx
    mov esi, ecx
    call malloc
    ;lea eax, [fdobjects + eax] ; FIXME: replace with malloc
    mov [eax + fat_fdobject.count], dword 1
    mov [eax + fat_fdobject.read], dword fat_read
    mov [eax + fat_fdobject.write], dword fat_write
    mov [eax + fat_fdobject.close], dword fat_close
    inc dword [fdobj_count]
    ret

;;; fat_fdobj* fat_open(const char* path, int flags)
;;; Gets the path of a file and returns an fdobj* referring to that file (NULL if not found)
fat_open:
    xor eax, eax
    xor ecx, ecx
    mov edx, dirtable
    push dword 11        ;; third and second arguments for i_memcmp
    lea  edx, [esp + 4]  ;; to call the function, I am only going to change the first one.
    push edx
    sub  esp, 4
    jmp  .found
    .loop
        mov eax, ecx
        ;cmp byte [dirtable + 32*eax + file_entry.name], 0
        je   .return
        lea  edx, [ecx + eax + file_entry.name]
        push edx
        call i_memcmp
        add  esp, 4
        inc  ecx ; ECX is the number of the file entry
        jmp  .loop
    .found
    call new_fat_fdobject
    test eax, eax
    jz   .return
    mov [eax + fat_fdobject.fid], ecx
    .not_found
        xor eax, eax
    .return
    add esp, 12
    ret

;;; size_t fat_file_size(int fid)
;;; Returns the size (in bytes) of the given file
fat_file_size:
    mov edx, [esp + 4]
    mov eax, [edx + file_entry.file_size]
    ret

;;; ssize_t fat_read(fat_fdobject* fdobj, void* dest, int count)
;;; Tries to read `fdobj->count` bytes from the file with the given fdobject at the right offset
;;; and returns the number of bytes read

;;; ^ lie and provocation
;;; offset and count are currently ignored
;;; it reads the whole file into the buffer (and also some trailing bytes till the end of the cluster)
;;; also, it always returns zero
fat_read:
    push ebp
    mov  ebp, esp
    push ebx
    push edi
    push esi
    xor ebx, ebx
    mov bx, [bootrecord + boot_record.bytes_per_sector]
    xor  ecx, ecx
    xor  edx, edx
    mov  edi, [ebp + 12]
    mov  ecx, [ebp + 8]
    mov  ecx, [ecx + fat_fdobject.fid]
    xor  esi, esi
    shl  ecx, 5 ; 2**5 == 32 == file_entry.size
    mov  si,  [dirtable + ecx + file_entry.start] ; the first cluster of the file
    ;;add  esi, ecx  ; offset inside the dirtable
    xor  ecx, ecx
    mov  cl,  [bootrecord + boot_record.sectors_per_cluster]
    .loop
        cmp  esi, 0FFFFh
        je  .end

        push ecx
        PRINT_NUM esi
        pop  ecx

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

fat_close:
    mov eax, [esp + 4]
    dec dword [eax + fat_fdobject.count]
    ; FIXME add free
    ret
