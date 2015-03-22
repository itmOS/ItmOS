;;;                                                      ;;;
;;; sprintf function implementation. Author: Dmitry Tomp ;;;
;;;                                                      ;;;

section .text

div10:  ; divide edx:eax by 10
        mov ecx, eax
        mov eax, edx
        xor edx, edx
        div ebx
        xchg eax, ecx
        div ebx
        xchg ecx, edx
        ; ecx - remainder
        ; edx:eax - quotient
        ret

; Print an unsigned long long in decimal representation.
; Nothing known about the format.
ulltoa: push ebp
        mov ebp, esp

        push ebx
        mov ebx, 10
        ; Arguments:
        ;  - edx:eax - the number
        ;  - edi - the destination
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
        mov edi, [ebp + 16]
.move:  ; determine the length of number,
        ; move edi to the end
        inc edi
        call div10
        test edx, edx
        jnz .move
        test eax, eax
        jnz .move
        mov byte [edi], 0 ; end of number is here
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
.put:   ; print the number moving backwards
        dec edi
        call div10
        add cl, '0'
        mov byte [edi], cl
        test edx, edx
        jnz .put
        test eax, eax
        jnz .put

        pop ebx
        mov esp, ebp
        pop ebp
        ret

; Format the number according to record in $esi.
; Called by sprintf, works with registers in place.
; Does not get any arguments from stack or preserve registers;
; ebx, esi and edi are used by sprintf afterwards.
ullformat:
        push ebp
        mov ebp, esp

        push esi ; store backups of all pointers to turn back
        push edi ; in case of a malformed sequence
        push ebx
        xor eax, eax
        xor ebx, ebx
        xor ecx, ecx
.flags: ; bl will hold a mask with needed booleans
        lodsb
        cmp al, '+'
        je ..@plus
        cmp al, ' '
        je ..@space
        cmp al, '-'
        je ..@minus
        cmp al, '0'
        jne .width
        or bl, ZERO_ALIGN
        jmp .flags
..@plus:
        or bl, PLUS
        jmp .flags
..@space:
        or bl, SPACE_SIGN
        jmp .flags
..@minus:
        or bl, ALIGN_LEFT
        jmp .flags
.width: ; ecx will hold the minimum width
        cmp al, '9'
        jg .size
        cmp al, '0'
        jl .size
        sub al, '0'
        shl ecx, 1 ; multiply ecx by 10
        mov edx, ecx
        shl edx, 2
        add ecx, edx
        add ecx, eax
        lodsb
        jmp .width
.size:  ; check for ll prefix
        cmp al, 'l'
        jne .type
        lodsb
        cmp al, 'l'
        jne .invalidSequence
        or bl, LONG_LONG
        lodsb
.type:  ; read the number type
        cmp al, '%'
        jne ..@aNumber
        stosb
        mov byte [edi], 0
        jmp .exit
..@aNumber
        mov bh, al
        mov eax, [esp]     ; ebx was pushed there - it points
        lea edx, [eax + 4] ; to the next function argument.
        mov eax, [eax]     ; load the lower part of number
        test bl, LONG_LONG
        jz ..@notLong
        mov edx, [edx] ; the higher part is on the stack
        jmp ..@checkSigned
..@notLong:
        xor edx, edx ; the higher part is zero
..@checkSigned:
        ; the character is in bh (eax is occupied)
        cmp bh, 'i'
        je .printSigned
        cmp bh, 'd'
        je .printSigned
        cmp bh, 'u'
        jne .invalidSequence
.printUll:
        test bl, PLUS
        jz ..@spaceSignUll
        mov byte [edi], '+'
        inc edi
        jmp .align
..@spaceSignUll:
        test bl, SPACE_SIGN
        jz .align
        mov byte [edi], ' '
        inc edi
        jmp .align
.printSigned:
        ; first check if the number is negative
        cmp edx, 0
        jg ..@printPlus
        jnz ..@printMinus
        cmp eax, 0
        jge ..@printPlus
..@printMinus:
        or bl, PLUS ; the sign is printed anyway; set the flag
        mov byte [edi], '-'
        inc edi
        ; we have printed the sign;
        ; let's negate the number and print as a positive one
        not eax
        inc eax
        test bl, LONG_LONG
        jz .align ; in this case, edx is already zero
        not edx
        adc edx, 0
        jmp .align
..@printPlus:
        test bl, PLUS
        jz ..@printSpace ; check for space attribute - no sign to print
        mov byte [edi], '+'
        inc edi
        jmp .align
..@printSpace:
        test bl, SPACE_SIGN
        jz .align
        mov byte [edi], ' '
        inc edi
.align:
        ; first print the number
        push ecx ; width will be messed by ulltoa; backing up
        push edi
        push edx
        push eax
        call ulltoa
        add esp, 12
        pop ecx
        or bl, PROCEED
        ; now let's align the number
        test bl, ALIGN_LEFT
        jz ..@alignRight
        ; aligning to the left
        mov edi, [esp + 4]
        cld
        repnz scasb
        jne .exit ; the last symbol was not \0; number enough long
        dec edi
        inc ecx
        mov al, ' '
        rep stosb
        mov byte [edi], 0
        jmp .exit
..@alignRight:
        inc ecx
        mov edx, esi
        mov esi, [esp + 4]
        ; if the empty space is filled with 0,
        ; the sign should be placed at the beginning
        test bl, ZERO_ALIGN
        jz ..@doTheJob
        test bl, ALWAYS_SIGN
        jz ..@doTheJob
        ; leave the sign at the beginning
        inc esi
        dec ecx
..@doTheJob:
        ; move towards the end of number
        mov edi, esi
        push ecx ; backup the width value
        cld
        repnz scasb
        ; place esi here, move edi to the final position
        mov esi, edi
        add edi, ecx
        ; ecx <- [esp] - ecx; free [esp]
        neg ecx
        add ecx, [esp]
        add esp, 4
        inc ecx
        ; copy the number to the right (move backwards)
        std
        rep movsb
        ; fill the remaining space with blank characters:
        ; first get length of remaining space
        mov ecx, edi
        sub ecx, esi
        mov esi, edx
        ; determine the blank character
        test bl, ZERO_ALIGN
        jz ..@spaceAlign
        mov al, '0'
        jmp ..@doClean
..@spaceAlign:
        mov al, ' '
..@doClean:
        rep stosb
        mov edi, [esp + 4]
        jmp .exit
.invalidSequence:
        ; print '%' as if it was not a special case;
        ; restore esi to the position next to '%'
        mov esi, [esp + 8]
        mov edi, [esp + 4]
        mov byte [edi], '%'
        mov byte [edi + 1], 0
        inc edi
.exit:
        ; check if the argument is consumed;
        ; move ebx to the right, in this case
        mov cl, bl
        pop ebx
        test cl, PROCEED
        jz ..@jumpBack
        add ebx, 4
        test cl, LONG_LONG
        jz ..@jumpBack
        add ebx, 4
..@jumpBack:
        ; registers are, of course, not preserved
        mov esp, ebp
        pop ebp
        ret

;;; WARNING!!! The signature differs from one in stdio.
;;; Variadic arguments are not passed themselves but
;;; as a pointer to their array.
;;; void sprintf(char *out, char const *format, void const *varargs)
global sprintf
sprintf:
        push ebp
        mov ebp, esp
        push esi
        push edi
        push ebx

        mov edi, [ebp + 8]
        mov esi, [ebp + 12]
        mov ebx, [ebp + 16] ; points to the variadic arguments
.loop:
        lodsb
        test al, al
        jz .exit ; end of the C string
        cmp al, '%'
        jne ..@justPrint
        ; it pretends to be a sequence
        call ullformat
        ; move edi to the end of output
        mov ecx, 0x7fffffff
        cld
        xor al, al
        repne scasb
        dec edi
        jmp .loop
..@justPrint:
        stosb
        jmp .loop
.exit:
        mov byte [edi], 0
        pop ebx
        pop edi
        pop esi
        mov esp, ebp
        pop ebp
        ret

; Flags (stored by bl in ullformat):
PLUS equ 1       ; whether the non-space sign is printed
SPACE_SIGN equ 2 ; whether the space is printed instead of '+'
ALWAYS_SIGN equ PLUS | SPACE_SIGN ; whether any sign is printed
ALIGN_LEFT equ 4 ; align to the left
ZERO_ALIGN equ 8 ; fill with zeroes
LONG_LONG equ 16 ; the long long was requested
SIGNED equ 32    ; print the signed number
PROCEED equ 64   ; the function argument was consumed
