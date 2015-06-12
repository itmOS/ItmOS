%ifndef MEM_MACRO_INC
%define MEM_MACRO_INC

KERNEL_PHY              equ 0x400000
PAGE_SIZE               equ 0x1000
PAGE_SIZE_OFFSET        equ 12
WINDOW                  equ 0xFFFFF000
WINDOW2                 equ 0xFFFFE000
WINDOW_PAGE_NUMBER      equ 1023
KERNEL_ACCESS_MODE      equ 0x3
DEFAULT_ACCESS_MODE     equ 0x7

%macro CLEAR 2
        pusha
        mov eax, %1
        mov ecx, %2
%%loop:
        test ecx, ecx
        jz %%exit
        dec ecx
        mov byte [eax + ecx], 0
        jmp %%loop
%%exit: 
        popa
%endmacro

%macro SAFE_WINDOW 1
        push eax
        CCALL map_to_window, %1
        pop eax
%endmacro

%macro SAFE_WINDOW2 1
	push eax
	CCALL map_to_window2, %1
	pop eax
%endmacro

%macro LOCK_MUTEX 0
%%start:        
        cmp byte [mutex], 0
        je %%lock
        hlt
        jmp %%start
%%lock:
        mov byte [mutex], 1
%endmacro

%macro UNLOCK_MUTEX 0
        mov byte [mutex], 0
%endmacro

;;; Gets new physical page, maps to window and cleans it
%macro NEW_CLEAN_PHYSPAGE 0
        CCALL get_pages, dword 1
        test eax, eax
        jz %%exit

        pusha

        SAFE_WINDOW eax
        mov dword ecx, 1024
%%loop:
        test ecx, ecx
        jz %%finish
        dec ecx
        mov dword [WINDOW + ecx * 4], 0
        jmp %%loop
%%finish
        popa
%%exit: 
%endmacro

%endif 
