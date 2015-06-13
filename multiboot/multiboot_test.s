%include "tty/tty.inc"
%include "multiboot/multiboot.inc"

section .text

global mmap_print
mmap_print:
    BOOTINFO_TEST_FLAG BOOTINFO_BIOS_MMAP ; test whether GRUB has provided this
    jz .error
    push esi
    push ebx
    push ecx
    push edx
    BOOTINFO_GET_MMAP_LENGTH ebx ; Get memory map array length in bytes
    BOOTINFO_GET_MMAP_ITER esi   ; Get the first entry pointer
    xor edx, edx ; edx is an entry number
    add ebx, esi ; ebx points to the end of array
.loop:
    cmp esi, ebx ; Check whether we are beyond the array already
    jge .exit
    inc edx
    lea ecx, BOOTINFO_MMAP_LENGTH(esi)   ; Get range length from entry pointer
    mov eax, [ecx + 4]                   ; (it is long long, should be pushed in 2 parts)
    push eax
    mov eax, [ecx]
    push eax
    lea ecx, BOOTINFO_MMAP_BASEADDR(esi) ; Get base address from entry pointer
    mov eax, [ecx + 4]                   ; (once again, long long)
    push eax
    mov eax, [ecx]
    push eax
    push edx
    push mmap_reg
    TTY_PRINTF
    mov edx, [esp + 4] ; restore the entry number from stack
    add esp, 24
    cmp BOOTINFO_MMAP_TYPE(esi), 1 ; Test whether an entry type is RAM
    jne .reserved                  ; (also may be reserved for a device, see Detecting Memory on osdev.org)
    TTY_PUTS mmap_ram
    BOOTINFO_MMAP_NEXT esi ; Move the pointer to the next array entry
    jmp .loop
.reserved:
    TTY_PUTS mmap_res
    BOOTINFO_MMAP_NEXT esi ; Move the pointer to the next array entry
    jmp .loop
.error:
    TTY_PUTS mmap_inv ; Memory map is invalid, print something
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
          db '    base address %llu', 10
          db '    length       %llu', 10
          db '    type         ', 0
mmap_ram: db 'RAM', 10, 0
mmap_res: db 'reserved', 10, 0
