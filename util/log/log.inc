%ifndef UTIL_LOG_INC
%define UTIL_LOG_INC

%include "tty/tty.inc"

extern log_ok
extern log_err
extern log_warn
extern log_bochs_console
extern log_errf
extern log_warnf
extern log_okf

%macro LOG_OK 1
push %1
call log_ok
add esp, 4
%endmacro 

%macro LOG_ERR 1
push %1
call log_err
add esp, 4
%endmacro

%macro LOG_WARN 1
push %1
call log_warn
add esp, 4
%endmacro

%macro LOG_SIMPLE 1
push esi
push eax
mov esi, %1
call tty_puts
mov al, 10
call tty_putc
pop eax
pop esi
%endmacro

%macro LOG_BOCHS_CONSOLE 1
push eax
mov eax, %1
push eax
call log_bochs_console
add esp, 4
pop eax
%endmacro

%endif ; UTIL_LOG_INC