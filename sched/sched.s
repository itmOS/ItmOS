%include "interrupts/interrupts.inc"
%include "boot/boot.inc"
%include "util/macro.inc"
%include "tty/tty.inc"
%include "fs/fs.inc"
%include "dev/mem/sbrk.inc"

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
    mov dword [tss_table + TSS.esp0], tss_table + TSS.stackTop - 4
    mov word [tss_table + TSS.ss0], PRIVILEGED_DATA
    mov eax, cr3
    mov [tss_table + TSS.cr3], eax
    mov ebp, esp
    mov esp, tss_table + TSS.stackTop
    pushf
    mov esp, ebp
    mov dword [tss_table + TSS.stackTop - 4], kernel_routine
    mov dword [tss_table + TSS.status], RUNNING
    mov dword [tss_table + TSS.esp], tss_table + TSS.stackTop - 4

    mov eax, tss_table + TSS_size
    switchTss
    mov dword [tss_table + TSS_size + TSS.esp0], tss_table + TSS_size + TSS.stackTop - 4
    mov word [tss_table + TSS_size + TSS.ss0], PRIVILEGED_DATA
    call new_page_table
    mov [tss_table + TSS_size + TSS.cr3], eax
    mov dword [tss_table + TSS_size + TSS.stackTop - 4],   USERSPACE_DATA
    mov dword [tss_table + TSS_size + TSS.stackTop - 8], 5 * 1024 - 4
    mov dword [tss_table + TSS_size + TSS.stackTop - 12], USERSPACE_CODE
    mov dword [tss_table + TSS_size + TSS.stackTop - 16], 4 * 1024
    mov dword [tss_table + TSS_size + TSS.status], BLOCKED
    mov dword [tss_table + TSS_size + TSS.esp], tss_table + TSS_size + TSS.stackTop - 16

    mov cr3, eax
    cld
    mov esi, userspace
    mov edi, 4 * 1024
    mov ecx, userspace_end - userspace
    rep movsb
    extern test_userspace
	mov esi, test_userspace
	lea edi, [4 * 1024 + userspace_end - userspace]
	mov ecx, 1024
    rep movsb
    ADD_SYSTEM_FUNCTION 0, exit
    ADD_SYSTEM_FUNCTION 2, writeScreen
    ADD_SYSTEM_FUNCTION 6, fork
    ADD_SYSTEM_FUNCTION 9, waitpid
    mov esp, [tss_table + TSS_size + TSS.esp]
    INITHANDLER context_switch, IRQ_BASE, 0x8E00
    loadUserspaceSel
    retf ; Diving into our first user process!

userspace:
    lea eax, [4 * 1024 + userspace_end - userspace]
    call eax
    mov word [5 * 1024], 0
    mov eax, 6
    int 0x80
    push eax
    test eax, eax
    jz .child
    mov byte [5 * 1024], 'P'
    mov ecx, 20
    jmp .printer
.child:
    mov byte [5 * 1024], 'C'
    mov ecx, 60
.printer:
    test ecx, ecx
    jz .wait
    mov eax, 2
    mov edi, 2
    mov esi, 5 * 1024
    push ecx
    int 0x80
    pop ecx
    dec ecx
    jmp .printer
.wait:
    pop edi
    test edi, edi
    jz .childComputing
    mov eax, 9
    int 0x80
    mov esi, parString - userspace + 4 * 1024
    cmp eax, 123
    je .exit
    mov esi, parentWut - userspace + 4 * 1024
    jmp .exit
.childComputing:
    mov eax, 2
    mov edi, 2
    mov esi, chlBusy - userspace + 4 * 1024
    int 0x80
.loop:
    inc ecx
    cmp ecx, 100000000
    jl .loop
    mov esi, chlString - userspace + 4 * 1024
.exit:
    mov eax, 2
    mov edi, 2
    int 0x80
    xor eax, eax
    mov edi, 123
    int 0x80

parentWut: db 'parent: failed to wait for child, wtf', 10, 0
parString: db 'parent: waited for child, finished', 10, 0
chlString: db 'child: exited', 10, 0
chlBusy:   db 'child: performing a complex computation', 10, 0
  userspace_end

exit:
    mov eax, [kernel_loop]
    mov dword [tss_table + eax + TSS.status], edi
    mov eax, [tss_table + eax + TSS.parent]
    shr eax, TSS_POWER
    push eax
    call unblock_pid
    jmp kernel_routine

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

exec:
    CCALL fat_open, edi, FAT_READ
    cmp eax, -1
    jne .good
    ret
.good:
    mov ecx, eax
    call new_page_table
    cmp eax, -1
    jne .excellent
    CCALL fat_close, ecx
    ret
.excellent:
    mov edx, eax
    push ecx
    push edx
    xor ebx, ebx
    mov edi, esi
.countLengths:
    cmp dword [edi], 0
    je .enough
    CCALL i_strlen, [edi]
    add ebx, eax
    inc ebx
    add edi, 4
    jmp .countLength
.enough:
    CCALL malloc, ebx
    mov edi, eax
    mov ebx, eax
    mov edx, esi
.copyIt:
    mov esi, [edx]
    test esi, esi
    jz .copied
    xor eax, eax
    mov ecx, 0x7fffffff
    repne movsb
    add edx, 4
    jmp .copyIt
.copied:
    ; currently using:
    ; ebx - kernel buffer begin
    ; edi - kernel buffer end
    pop edx
    mov ecx, [kernel_loop]
    mov [tss_table + ecx + TSS.cr3], edx
    mov ecx, cr3
    push ecx
    mov cr3, edx

    lea ecx, [edi + 4 * 1024 * 1024 + 1]
    sub ecx, ebx
    SBRK ecx, USER_HEAP_BEGIN, USER_HEAP_END, USER_FLAG
    mov esi, ebx
    mov edi, 4 * 1024 * 1024
    sub ecx, 4 * 1024 * 1024 + 1
    rep movsb

    mov ebx, [esp + 4]
    mov edi, 4 * 1024
.readIt:
    CCALL dword [ebx + fd_obj.read], ebx, edi, 4 * 1024 * 1023
    cmp eax, -1
    je .ohGodWhyHere
    test eax, eax
    jz .fascinating
    add edi, eax
.fascinating:
    CCALL free_page_table, [esp]
    CCALL [ebx + fd_obj.close], ebx
    add esp, 8
    ret
.ohGodWhyHere:
    CCALL [ebx + fd_obj.close], ebx
    mov ecx, cr3
    pop edx
    mov cr3, edx
    CCALL free_page_table, ecx
    add esp, 4
    mov eax, -1
    ret

fork:
    CCALL dup_page_table, cr3
    test eax, eax
    jz .failure
    mov edx, eax
    mov ebx, [proc_count]
    mov eax, [kernel_loop]
    mov ecx, TSS_size / 4
    lea esi, [tss_table + eax]
    lea edi, [tss_table + ebx]
    rep movsd
    mov [tss_table + ebx + TSS.cr3], edx
    mov [tss_table + ebx + TSS.parent], eax
    mov ecx, ebx
    sub ecx, [kernel_loop]
    add [tss_table + ebx + TSS.esp0], ecx
    lea ecx, [ecx + esp - 4]
    mov [tss_table + ebx + TSS.esp], ecx
    mov dword [tss_table + ebx + TSS.status], RUNNING
    mov dword [ecx], .childProcess
    shr ebx, TSS_POWER
    lock add dword [proc_count], TSS_size
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
    mov eax, [kernel_loop]
    shr eax, TSS_POWER
    ret

global suspend_syscall
suspend_syscall:
    pusha
    mov eax, [cur_process]
    test eax, eax
    jz .kernel
    mov dword [tss_table + eax + TSS.status], CALLING
    call context_switch.systemFunction
    jmp .return
.kernel:
    pushf
    mov eax, [kernel_loop]
    cli ; Danger zone: same as in syscall_finished
    lea ecx, [esp - 4]
    mov dword [tss_table + eax + TSS.status], BLOCKED
    mov [tss_table + eax + TSS.esp], ecx
    call kernel_routine
    popf
.return:
    popa
    ret

global unblock_pid
unblock_pid:
    mov ecx, [esp + 4]
    shl ecx, TSS_POWER
    mov eax, BLOCKED
    mov edx, CALLING
    cmpxchg [tss_table + ecx + TSS.status], edx
    ret

kernel_routine:
    sti
    mov eax, [kernel_loop]
    mov ecx, eax
.loopThrough:
    add eax, TSS_size
    cmp eax, [proc_count]
    jl .anybodyThere
    mov eax, TSS_size
.anybodyThere:
    cmp dword [tss_table + eax + TSS.status], CALLING
    je .consider
    cmp eax, ecx
    jne .loopThrough
    mov dword [tss_table + TSS.status], BLOCKED
    push eax
    push ecx
    cli
    call context_switch.systemFunction
    jmp kernel_routine
.consider:
    mov [kernel_loop], eax
    mov ecx, [tss_table + eax + TSS.cr3]
    mov [tss_table + TSS.cr3], ecx
    mov cr3, ecx
    mov esp, [tss_table + eax + TSS.esp]
    ret

global syscall_finished
syscall_finished:
    cmp dword [cur_process], 0
    jne .return
    push eax
    mov eax, [kernel_loop]
    cli ; Danger zone: putting a return address on the stack
        ; and switching it
    lea ecx, [esp - 4]
    mov [tss_table + eax + TSS.esp], ecx
    mov dword [ecx], .ourProcess
    mov dword [tss_table + eax + TSS.status], RUNNING
    mov esp, tss_table + TSS.stackTop - 4
    jmp kernel_routine
.ourProcess:
    pop eax
.return
    ret

context_switch:
    mov esi, 1
    jmp .start
.systemFunction:
    xor esi, esi
.start:
    mov eax, [cur_process]
    mov ecx, eax
    mov [tss_table + eax + TSS.esp], esp
    shr eax, TSS_POWER
    mov ebx, eax
    mov edx, [proc_count]
    shr edx, TSS_POWER
.loop:
    cmp dword [tss_table + ecx + TSS.status], CALLING
    jne .contLoop
    mov dword [tss_table + TSS.status], RUNNING
.contLoop:
    inc eax
    cmp eax, edx
    jl .check
    xor eax, eax
.check:
    mov ecx, eax
    shl ecx, TSS_POWER
    cmp dword [tss_table + ecx + TSS.status], RUNNING
    je .consider
    cmp eax, ebx
    jne .loop
    jmp .halt
.consider:
    mov eax, ecx
    mov [cur_process], eax
    add eax, tss_table
    switchTss
    mov ecx, [eax + TSS.cr3]
    mov cr3, ecx
    mov esp, [eax + TSS.esp]
    test esi, esi
    jz .return
    NOTIFYPIC
.return:
    ret
.halt:
    test esi, esi
    jz .finish
    NOTIFYPIC
.finish:
    DISABLE_MASTER_BIT 0x01
    sti
    hlt
    cli
    ENABLE_MASTER_BIT 0x01
    jmp .systemFunction

global waitpid
waitpid:
    shl edi, TSS_POWER
    mov eax, [kernel_loop]
    cmp eax, [tss_table + edi + TSS.parent]
    jne .failure
.loop:
    mov eax, [tss_table + edi + TSS.status]
    cmp eax, 0
    jge .return
    call suspend_syscall
    jmp .loop
.return:
    ret
.failure:
    mov eax, -1
    ret

global get_fd_object
get_fd_object:
    mov ecx, [esp + 4]
    mov eax, [kernel_loop]
    mov eax, [tss_table + eax + TSS.fdTable + 4 * ecx]
    ret

global add_fd_object
add_fd_object:
    push edi
    mov edi, [kernel_loop]
    lea edi, [tss_table + edi + TSS.fdTable]
    mov edx, edi
    mov ecx, MAX_FD
    xor eax, eax
    cld
    repne scasd
    test ecx, ecx
    jz .failure
    sub edi, 4
    mov ecx, [esp + 8]
    mov [edi], ecx
    mov eax, edi
    sub eax, edx
    shr eax, 2
    pop edi
    ret
.failure:
    mov eax, -1
    pop edi
    ret

section .data

proc_count   dd TSS_size * 2
cur_process  dd TSS_size
kernel_loop  dd TSS_size

section .rodata

goodbye: db 'All processes finished. Shutting down.', 10, 0

section .bss

tss_descr    resd 1

align 4096
global tss_table
tss_table:
    times PROCESS_LIMIT resb TSS_size

MAX_FD        equ 64
TSS_POWER     equ 10
PROCESS_LIMIT equ 256

;; Process statuses:
RUNNING equ -1
CALLING equ -2
BLOCKED equ -3

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
    .parent   resd 1
    .fdTable  resd MAX_FD
    .stackBot resb ((1 << TSS_POWER) - $)
    .stackTop
endstruc
