%include "interrupts/interrupts.inc"
%include "boot/boot.inc"
%include "util/macro.inc"
%include "tty/tty.inc"

extern new_page_table
extern dup_page_table

section .text

global init_tss
init_tss:
    mov [tss_descr], edi
    mov [edi], word TSS_size
    ret

%macro switchTss 0
    mov ecx, eax
    shr ecx, 16
    mov edi, [tss_descr]
    mov [edi + 7], ch
    mov [edi + 5], word 0x00E9
    mov [edi + 4], cl
    mov [edi + 2], ax
    mov cx, TSS_DESCR
    ltr cx
%endmacro

%macro loadUserspaceSel 0
    mov cx, USERSPACE_DATA
    mov ds, cx
    mov es, cx
    mov fs, cx
    mov gs, cx
%endmacro

global sch_bootstrap
sch_bootstrap:
    mov eax, tss_table
    switchTss
    add dword [proc_count], TSS_size
    mov dword [tss_table + TSS.esp0], tss_table + TSS.stackTop - 4
    mov word [tss_table + TSS.ss0], PRIVILEGED_DATA
    call new_page_table
    mov [tss_table + TSS.cr3], eax
    mov dword [tss_table + TSS.stackTop - 4], USERSPACE_DATA
    mov dword [tss_table + TSS.stackTop - 8], 5 * 1024 - 1
    mov dword [tss_table + TSS.stackTop - 12], USERSPACE_CODE
    mov dword [tss_table + TSS.stackTop - 16], 4 * 1024
    mov dword [tss_table + TSS.status], -1
    mov dword [tss_table + TSS.esp], tss_table + TSS.stackTop - 16
    mov byte [process_ready], 2

    mov cr3, eax
    cld
    mov esi, userspace
    mov edi, 4 * 1024
    mov ecx, userspace_end - userspace
    rep movsb
    ADD_SYSTEM_FUNCTION 0, exit
    ADD_SYSTEM_FUNCTION 2, writeScreen
    ADD_SYSTEM_FUNCTION 6, fork
    mov esp, [tss_table + TSS.esp]
    IRQINITHANDLER context_switch, IRQ_BASE, 0x8E00
    loadUserspaceSel
    retf ; Diving into our first user process!

userspace:
    mov dword [5 * 1024], 0
    mov byte [5 * 1024], 'P'
    mov byte [5 * 1024 + 2], 'C'
    mov eax, 6
    int 0x80
    mov ecx, 40
    test eax, eax
    jz .child
.parent:
    test ecx, ecx
    jz .exit
    mov eax, 2
    mov edi, 2
    mov esi, 5 * 1024
    push ecx
    int 0x80
    pop ecx
    dec ecx
    jmp .parent
.child:
    test ecx, ecx
    jz .exit
    mov eax, 2
    mov edi, 2
    mov esi, 5 * 1024 + 2
    push ecx
    int 0x80
    pop ecx
    dec ecx
    jmp .child
.exit:
    xor eax, eax
    xor edi, edi
    int 0x80
userspace_end

exit:
    mov eax, [cur_process]
    mov dword [tss_table + TSS.status + eax], edi
    sti
    hlt

writeScreen:
    cmp edi, 2
    jne .failure
    cmp esi, KERNEL_VMA
    jle .failure
    TTY_PUTS esi
    xor eax, eax
    ret
.failure:
    mov eax, -1
    ret

fork:
    CCALL dup_page_table, cr3
    test eax, eax
    jz .failure
    mov edx, eax
    mov ebx, TSS_size
    lock xadd [proc_count], ebx
    mov eax, [cur_process]
    mov ecx, TSS_size / 4
    lea esi, [tss_table + eax]
    lea edi, [tss_table + ebx]
    rep movsd
    mov [tss_table + ebx + TSS.cr3], edx
    mov ecx, ebx
    sub ecx, [cur_process]
    add [tss_table + ebx + TSS.esp0], ecx
    lea ecx, [ecx + esp - 4]
    mov [tss_table + ebx + TSS.esp], ecx
    mov dword [tss_table + ebx + TSS.status], -1
    mov dword [ecx], .childProcess
    shr ebx, TSS_POWER
    mov byte [process_ready + ebx], 1
    mov eax, ebx
    ret
.childProcess:
    xor eax, eax
    ret
.failure:
    mov eax, -1
    ret

global current_pid
current_pid:
    mov eax, [cur_process]
    shr eax, TSS_POWER
    ret

context_switch:
    mov eax, [cur_process]
    mov [tss_table + eax + TSS.esp], esp
    shr eax, TSS_POWER
    mov byte [process_ready + eax], 2
    mov edx, [proc_count]
    shr edx, TSS_POWER
    mov ecx, eax
.loop:
    inc eax
    cmp eax, edx
    jl .check
    xor eax, eax
    cmp eax, ecx
    je .shutdown
.check:
    mov bl, [process_ready + eax]
    test bl, bl
    je .loop
    mov esi, eax
    shl esi, TSS_POWER
    cmp dword [tss_table + esi + TSS.status], -1
    jne .loop
    mov eax, esi
    mov [cur_process], eax
    add eax, tss_table
    switchTss
    mov ecx, [eax + TSS.cr3]
    mov cr3, ecx
    mov esp, [eax + TSS.esp]
    cmp bl, 2
    je .return
    NOTIFYPIC
.return:
    ret
.shutdown:
    hlt

global waitpid
waitpid:
    mov ecx, [esp + 4]
    shl ecx, TSS_POWER
.loop:
    mov eax, [tss_table + ecx + TSS.status]
    cmp eax, -1
    jne .return
    hlt
    jmp .loop
.return:
    ret

global get_fd_object
get_fd_object:
    mov eax, [cur_process]
    mov eax, [cur_process + TSS.fdTable + 4 * edi]
    ret

global add_fd_object
add_fd_object:
    mov esi, [cur_process]
    lea esi, [tss_table + ecx + TSS.fdTable]
    mov edx, esi
    mov ecx, MAX_FD
    xor eax, eax
    repnz lodsd
    test ecx, ecx
    jz .failure
    mov [esi], edi
    mov eax, esi
    sub eax, edx
    shl eax, 2
    ret
.failure:
    mov eax, -1
    ret

section .data

proc_count   dd 0
cur_process  dd 0
tss_descr    dd 0

process_ready: times PROCESS_LIMIT db 0

section .bss

align 4096
global tss_table
tss_table:
    times PROCESS_LIMIT resb TSS_size

MAX_FD        equ 64
TSS_POWER     equ 10
PROCESS_LIMIT equ 256

struc TSS
              resd 1
    .esp0     resd 1
    .ss0      resw 1
              resw 1
    .esp1     resd 1
    .ss1      resw 1
              resw 1
    .esp2     resd 1
    .ss2      resw 1
              resw 1
    .cr3      resd 1
    .esp      resd 1
    align 4
    .status   resd 1
    .fdTable  resd MAX_FD
    .stackBot resb ((1 << TSS_POWER) - $)
    .stackTop
endstruc
