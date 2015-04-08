%ifndef AUX_LOG_INC
%define AUX_LOG_INC

extern log_ok
extern log_err
extern log_warn

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

%endif ; AUX_LOG_INC