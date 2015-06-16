%ifndef SYSCALLS_MACRO_INC
%define SYSCALLS_MACRO_INC

;; Use this from the syscall body to call the real implementation
%macro FORWARD_SYSCALL_ARGS 1
       push edx
       push ebx
       push esi
       push edi

       call %1

       add esp, 16
%endmacro

%endif
