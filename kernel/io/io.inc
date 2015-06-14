%ifndef KERNEL_IO_IO_INC
%define KERNEL_IO_IO_INC

%include "kernel/io/structs.inc"

IO_WOULD_BLOCK: equ -(1 << 1)

IO_READ: equ (1 << 1)
IO_WRITE: equ (1 << 1)
IO_CLOSE: equ (1 << 1)

;; see io.h
extern io_notify_available

%endif
