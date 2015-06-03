%ifndef SYS_STAT_H
%define SYS_STAT_H

;; Zero or more flags can be bitwise-or'd
O_RDONLY: equ 1
O_WRONLY: equ 1 << 1
O_RDWR: equ 1 << 2
O_CREAT: equ 1 << 3
O_DIRECTORY: equ 1 << 4
O_APPEND: equ 1 << 5

%endif
