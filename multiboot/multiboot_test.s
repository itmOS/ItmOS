%include "tty/tty.inc"
%include "multiboot/multiboot.inc"

section .text

global mmap_print
mmap_print:
    BOOTINFO_TEST_FLAG BOOTINFO_BIOS_MMAP
    jz .error
    push esi
    push ebx
    push ecx
    push edx
    BOOTINFO_GET_MMAP_LENGTH ebx
    push ebx
    push mmap_cnt
    TTY_PRINTF
    add esp, 4
    pop ebx
    BOOTINFO_GET_MMAP_ITER esi
    xor edx, edx
    add ebx, esi
.loop:
    cmp esi, ebx
    je .exit
    inc edx
    mov eax, BOOTINFO_MMAP_LENGTH(esi)
    push eax
    lea ecx, BOOTINFO_MMAP_BASEADDR(esi)
    mov eax, [ecx + 4]
    push eax
    mov eax, [ecx]
    push eax
    push edx
    push mmap_reg
    TTY_PRINTF
    mov edx, [esp + 4]
    add esp, 20
    cmp BOOTINFO_MMAP_TYPE(esi), 1
    jne .reserved
    TTY_PUTS mmap_ram
    BOOTINFO_MMAP_NEXT esi
    jmp .loop
.reserved:
    TTY_PUTS mmap_res
    BOOTINFO_MMAP_NEXT esi
    jmp .loop
.error:
    TTY_PUTS mmap_inv
    ret
.exit:
    pop edx
    pop ecx
    pop ebx
    pop esi
    ret

section .rodata
mmap_inv: db 'Memory map info unavailable, check boot header', 10, 0
mmap_cnt: db 'Total memory map regions: %d', 10, 0
mmap_reg: db 'Map region %d:', 10
          db '    base address %lld', 10
          db '    length       %d', 10
          db '    type         ', 0
mmap_ram: db 'RAM', 10, 0
mmap_res: db 'reserved', 10, 0
