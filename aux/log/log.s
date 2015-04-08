;;; This file contains some coroutines for the logging.

%include "tty/tty.inc"

global log_ok
global log_err
global log_warn

section .text

;;; void log_ok(char* message)
;;; Log the normal info message.
log_ok:	
	push esi

	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_GREEN), ok_message
	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_GREEN), [esp + 12]
	TTY_PUTC 10

	pop esi
	ret

;;; void log_err(char* message)
;;; Log the error message.
log_err:	
	push esi

	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_RED), err_message
	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_RED), [esp + 12]
	TTY_PUTC 10

	pop esi
	ret

;;; void log_warn(char* message)
;;; Log the warning message.
log_warn:	
	push esi

	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_YELLOW), warn_message
	TTY_PUTS_STYLED TTY_STYLE(TTY_BLACK, TTY_YELLOW), [esp + 12]
	TTY_PUTC 10

	pop esi
	ret

section .data
ok_message:   db "[OK]   ", 0
err_message:  db "[ERR]  ", 0
warn_message: db "[WARN] ", 0
