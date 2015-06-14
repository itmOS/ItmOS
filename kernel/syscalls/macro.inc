%ifndef SYSCALLS_MACRO_INC
%define SYSCALLS_MACRO_INC

;; Use this from the syscall body to call the real implementation
%macro FORWARD_SYSCALL_ARGS 2
       %if %2 > 0
       push edi
       %if %2 > 1
       push esi
       %if %2 > 2
       push ebx
       %if %2 > 3
       push edx
       %endif
       %endif
       %endif
       %endif

       call %1

       add esp, %2 * 4
%endmacro

%endif
