%include "util/mem/mem.inc"
%include "boot/boot.inc"

section .text

global fill_in_tss
fill_in_tss:
    mov eax, tss_table
    mov ecx, PROCESS_LIMIT
.loop:
    mov [edi], eax
    mov [edi + 2], eax
    mov word [edi + 1], 0x00E9
    mov word [edi + 6], TSS_size
    add eax, TSS_size
    add edi, 8
    sub ecx, 1
    jnz .loop
    ret

global exec
exec:
    push edi
    push esi
    push ebx
    mov ebx, TSS_size
    lock xadd [proc_count], ebx
    mov eax, [cur_process]
    mov ecx, TSS_size / 4
    lea esi, [tss_table + eax]
    mov edx, [proc_count]
    lea edi, [tss_table + eax]
    rep movsd
    DUP_PAGE_TABLE
    mov [tss_table + ebx + TSS.cr3], eax
    mov eax, [esp + 4]
    mov [tss_table + ebx + TSS.eip], eax
    shr ebx, TSS_POWER
    mov byte [process_ready + ebx], 1
    pop ebx
    pop esi
    pop edi
    ret

global process_lock
process_lock:
    mov byte [process_locked], 1
    ret

global process_unlock
process_unlock:
    mov byte [process_locked], 0
    ret

global current_pid
current_pid:
    mov eax, [cur_process]
    shr eax, TSS_POWER
    ret

context_switch:
    cmp byte [process_locked], 0
    je .switch
    iret
.switch:
    mov byte [process_locked], 1
    mov eax, [cur_process]
    mov ecx, eax
    shl ecx, TSS_POWER
    mov edx, [proc_count]
.loop:
    add eax, TSS_POWER
    inc ecx
    cmp eax, edx
    jl .check
    xor eax, eax
    xor ecx, ecx
.check:
    cmp byte [process_ready + ecx], 0
    je .loop
    mov byte [process_locked], 0
    lea cx, [cx * 8 + TSS_BEGIN]
    jmp cx:.return
.return:
    iret

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
    mov ecx, (TSS_size - TSS.fdTable) / 4
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

process_locked:  db 1
process_ready: times PROCESS_LIMIT db 0

section .bss

align 4096
tss_table: times PROCESS_LIMIT resb TSS_size

TSS_POWER equ 7

struc TSS
    .prevTask resw 1
              resw 1 
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
    .eip      resd 1
    .eflags   resd 1
    .eax      resd 1
    .ecx      resd 1
    .edx      resd 1
    .ebx      resd 1
    .esp      resd 1
    .ebp      resd 1
    .esi      resd 1
    .edi      resd 1
    .es       resw 1
              resw 1
    .cs       resw 1
              resw 1
    .ss       resw 1
              resw 1
    .ds       resw 1
              resw 1
    .fs       resw 1
              resw 1
    .gs       resw 1
              resw 1
    .ldtSel   resw 1
              resw 1
    .trapFlag resw 1
    .ioMap    resw 1
    .status   resd 1
    align 4
    .fdTable  resb ((1 << TSS_POWER) - $)
endstruc
