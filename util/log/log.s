;;; This file contains some coroutines for the logging.

%include "util/macro.inc"
%include "tty/tty.inc"

global log_ok
global log_err
global log_warn
global log_bochs_console

section .text

;;; void log_ok(char* message)
;;; Log the normal info message.
log_ok:	
	push esi

	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_GREEN), ok_message
	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_GREEN), [esp + 12]
	TTY_PUTC 10

%ifdef ENABLE_LOG_BOCHS_CONSOLE
	CCALL log_bochs_console, ok_message
	CCALL log_bochs_console, [esp + 12]
	CCALL log_bochs_console, endline
%endif
	pop esi
	ret

;;; void log_err(char* message)
;;; Log the error message.
log_err:	
	push esi

	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_RED), err_message
	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_RED), [esp + 12]
	TTY_PUTC 10

%ifdef ENABLE_LOG_BOCHS_CONSOLE
	CCALL log_bochs_console, ok_message
	CCALL log_bochs_console, [esp + 12]
	CCALL log_bochs_console, endline
%endif

	pop esi
	ret

;;; void log_warn(char* message)
;;; Log the warning message.
log_warn:	
	push esi

	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_YELLOW), warn_message
	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_YELLOW), [esp + 12]
	TTY_PUTC 10

%ifdef ENABLE_LOG_BOCHS_CONSOLE
	CCALL log_bochs_console, ok_message
	CCALL log_bochs_console, [esp + 12]
	CCALL log_bochs_console, endline
%endif

	pop esi
	ret

;;; void log_bochs_console(char* message)
;;; Log to the bochs console
log_bochs_console:
	push ebp
	mov ebp, esp
	push esi
	push eax

	mov esi, [ebp + 8]
	.loop:
	mov al, [esi]
	out 0xE9, al
	inc esi
	cmp byte [esi], 0
	je .end_loop
	jmp .loop
	.end_loop:

	pop eax
	pop esi
	pop ebp
	ret

section .data
ok_message:   db "[OK]   ", 0
err_message:  db "[ERR]  ", 0
warn_message: db "[WARN] ", 0
endline:      db 10,0
