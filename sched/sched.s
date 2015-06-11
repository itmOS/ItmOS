;%include "util/mem/mem.inc"
%include "boot/boot.inc"

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
    mov [edi + 4], cl
    mov [edi + 2], ax
    mov cx, TSS_DESCR
    ltr cx
%endmacro

global sch_bootstrap
sch_bootstrap:
    mov eax, tss_table
    switchTss
    add dword [proc_count], TSS_size
    mov dword [tss_table + TSS.esp0], tss_table + TSS.stackTop - 4
    mov word [tss_table + TSS.ss0], PRIVILEGED_DATA
    mov eax, cr3
    mov [tss_table + TSS.cr3], eax
    mov dword [tss_table + TSS.stackTop - 4], USERSPACE_DATA
    mov dword [tss_table + TSS.stackTop - 12], USERSPACE_CODE
    mov dword [tss_table + TSS.stackTop - 16], userspace - KERNEL_VMA
    mov dword [tss_table + TSS.esp], tss_table + TSS.stackTop - 16
    mov esp, [tss_table + TSS.esp]
    retf ; Diving into our first user process!

userspace:
    inc eax
    jmp near userspace

global fork
fork:
    mov ebx, TSS_size
    lock xadd [proc_count], ebx
    mov eax, [cur_process]
    mov ecx, TSS_size / 4
    lea esi, [tss_table + eax]
    mov edx, [proc_count]
    lea edi, [tss_table + eax]
    rep movsd
    ;DUP_PAGE_TABLE
    mov [tss_table + ebx + TSS.cr3], eax
    mov eax, [esp + 4]
    mov ecx, [tss_table + ebx + TSS.esp]
    mov [ecx], eax
    shr ebx, TSS_POWER
    mov byte [process_ready + ebx], 1
    ret

global current_pid
current_pid:
    mov eax, [cur_process]
    shr eax, TSS_POWER
    ret

context_switch:
    mov eax, [cur_process]
    mov [eax + TSS.esp], esp
    mov ecx, eax
    shl ecx, TSS_POWER
    mov edx, [proc_count]
.loop:
    add eax, TSS_size
    inc ecx
    cmp eax, edx
    jl .check
    xor eax, eax
    xor ecx, ecx
.check:
    cmp byte [process_ready + ecx], 0
    je .loop
    add eax, tss_table
    switchTss
    mov ecx, [eax + TSS.cr3]
    mov cr3, ecx
    mov esp, [eax + TSS.esp]
    ret

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
