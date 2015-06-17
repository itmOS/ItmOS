%ifndef TTY_INC
%define TTY_INC

extern tty_clear
extern tty_set_style
extern tty_puts
extern tty_putc
extern tty_delc
extern tty_endl
extern tty_save_style
extern tty_restore_style
extern tty_printf

%define TTY_BLACK 0
%define TTY_BLUE 1
%define TTY_GREEN 2
%define TTY_CYAN 3
%define TTY_RED 4
%define TTY_MAGENTA 5
%define TTY_BROWN 6
%define TTY_LIGHT_GRAY 7
%define TTY_GRAY 8
%define TTY_LIGHT_BLUE 9
%define TTY_LIGHT_GREEN 10
%define TTY_LIGHT_CYAN 11
%define TTY_LIGHT_RED 12
%define TTY_LIGHT_MAGENTA 13
%define TTY_YELLOW 14
%define TTY_WHITE 15

%define TTY_STYLE(bg, fg) 6 * (bg) + (fg)

%macro TTY_CLEAR 0
call tty_clear
%endmacro

%macro TTY_ENDL 0
call tty_endl
%endmacro

%macro TTY_SET_STYLE 1
push eax
mov al, %1 
call tty_set_style
pop eax
%endmacro

%macro TTY_PUTS 1
push esi
mov esi, %1
call tty_puts
pop esi
%endmacro

%define TTY_SAVE_STYLE call tty_save_style

%define TTY_RESTORE_STYLE call tty_restore_style

%define TTY_PRINTF call tty_printf

%macro TTY_PUTS_STYLED 2
TTY_SAVE_STYLE
TTY_SET_STYLE %1
TTY_PUTS %2
TTY_RESTORE_STYLE
%endmacro

%macro TTY_PUTC 1
push eax
mov al, %1
call tty_putc
pop eax
%endmacro

%macro TTY_DELC 0
call tty_delc
%endmacro

%endif ; TTY_INC
