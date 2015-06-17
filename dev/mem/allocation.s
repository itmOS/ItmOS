 section .text

%include "util/macro.inc"

extern sbrk

global malloc
global free

;;; void* malloc(int len)
;;; returns pointer to memory chunk of len bytes
malloc:
        mov eax, [esp + 4]
        add dword eax, 8

        push edi
        push esi
        push ebx
        push edx
        push ecx

        mov dword edx, 0xc0000000       ; set size to maximum
        xor edi, edi                    ; answer block
        xor esi, esi                    ; previous of answer block
        xor ebx, ebx                    ; previous
        mov dword ecx, [entry_point]    ; current block
.loop:
        ;; Check if loop finishing
        test ecx, ecx
        jz .exitloop

        ;; Check size of current block not less than needed
        cmp dword [ecx], eax
        jl .finishloop

        ;; Check size of current block less than current answer
        cmp dword [ecx], edx
        jge .finishloop
        ;; Update answer
        mov edx, [ecx]
        mov edi, ecx
        mov esi, ebx
.finishloop:
        ;; Move current to previous
        mov ebx, ecx
        ;; Move next to current
        mov dword ecx, [ecx + 4]
        jmp .loop
.exitloop:
        ;; If answer not found need to allocate memory
        test edi, edi
        jz .allocate
        ;; If found just same size that needed need to remove block
        cmp edx, eax
        je .remove
        ;; Otherwise decrease size of block
        sub [edi], eax
        mov ecx, [edi]
        add ecx, edi
        ;; Need to put size to the extracted part
        mov dword [ecx], eax
        ;; We will return pointer to beginning + 8 bytes for malloc information
        mov eax, ecx
        add dword eax, 8
        jmp .exit
.remove:
        ;; Get next of answer
        mov dword ecx, [edi + 4]
        ;; Check if answer has previous
        test esi, esi
        jnz .notfirst
        ;; If not update entry point
        mov dword [entry_point], ecx
        ;; Size is already set
        mov eax, edi
        ;; We will return pointer to beginning + 8 bytes for malloc information
        add dword eax, 8
        jmp .exit
.notfirst:
        ;; If not first update next of previous block
        mov [esi + 4], ecx
        ;; Size is already set
        ;; We will return pointer to beginning + 8 bytes for malloc information
        mov eax, edi
        add dword eax, 8
.exit:
        pop ecx
        pop edx
        pop ebx
        pop esi
        pop edi
        ret
.allocate:
        ;; If block not found need to get some memory
        mov edi, eax
        ;; Increase heap
        CCALL sbrk, eax
        ;; Check if successfull
        cmp dword eax, -1
        je .fail
        ;; sbrk returns pointer to beginning of allocated memory
        ;; Set size
        mov dword [eax], edi
        add dword eax, 8
        jmp .exit
.fail:
        xor eax, eax
        jmp .exit

;;; void free(void* addr)
;;; frees memory chunk starting from addr
free:
        ret
        mov dword eax, [esp + 4]
        pusha
        mov ecx, eax                    ; get left bound of block to add
        sub dword ecx, 8
        mov dword [ecx +  4], 0         ; set next to zero
        mov dword ebx, [ecx]            ; get size
        mov esi, ebx                    ; save size
        add ebx, ecx                    ; get right bound of block to add
        mov dword eax, [entry_point]     ; current block
        xor edx, edx                    ; previous of current block
.loop:
        test eax, eax
        jz .exitloop
        ;; Get its right bound
        mov dword edi, [eax]
        add edi, eax

        ;; Check if current block is on the left or on the right
        cmp ecx, eax
        jnl .rightbound

        ;; Check if current blocks left bound equal to right bound of block to add
        cmp ebx, eax
        je .eqrightbound
        ;; Put size
        mov [ecx], esi
        ;; Put current block as next
        mov [ecx + 4], eax

        jmp .exit_with_prev
.eqrightbound:   
        ;; Get size and next of current page
        mov dword edi, [eax]
        mov dword ebx, [eax + 4]
        ;; Just add page with sum of sizes of current and to add and current's next
        mov [ecx], esi
        add dword [ecx], edi
        mov [ecx + 4], ebx

        jmp .exit_with_prev
.rightbound:
        ;; If currents right bound is not equal to left bound of block to add
        ;; Can do nothing so continue
        cmp ecx, edi
        jne .finishloop
        ;; Otherwise add size of block to add to current
        add dword [eax], esi
        mov dword edx, [eax + 4]
        ;; Check if there is next
        test edx, edx
        ;; If not nothing to do - exit
        jz .exit
        ;; Set right bound of new block
        mov dword ebx, [eax]
        add ebx, eax
        ;; Check if its beginning is equal to new current blocks end
        cmp edx, ebx
        jne .exit
        ;; Get next's size
        mov dword ecx, [edx]
        ;; Get next's next
        mov dword edi, [edx + 4]
        ;; Add next's size to current block
        add dword [eax], ecx
        ;; Replace current's next with next's next
        mov dword [eax + 4], edi
        jmp .exit
.finishloop:
        ;; Set current to previous
        mov edx, eax
        ;; Set current next to current
        mov dword eax, [eax + 4]
        jmp .loop
.exitloop:
        ;; If we are here, block to add is after the last block
        ;; Or there are no blocks
        ;; Just add new block with no next
        mov dword [ecx], esi
        mov dword [ecx + 4], 0

        jmp .exit_with_prev
.exit:
        popa
        ret
.exit_with_prev:
        ;; Check if has previous
        test edx, edx
        jnz .set_prev
        ;; If not set begin page to point to block to add
        mov dword [entry_point], ecx
        jmp .exit
.set_prev:
        ;; Map previous and set next to block to add
        mov [edx + 4], ecx
        jmp .exit
        
        ret

entry_point:
        dd 0

