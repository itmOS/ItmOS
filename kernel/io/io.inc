%ifndef KERNEL_IO_IO_INC
%define KERNEL_IO_IO_INC

%include "kernel/io/structs.inc"
;; see io.h
extern io_notify_available
extern io_read
extern io_write
extern io_close
extern io_initialize

%endif
