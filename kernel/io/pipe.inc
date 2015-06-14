%ifndef KERNEL_IO_PIPE_INC
%define KERNEL_IO_PIPE_INC

;;; see pipe.h

PIPE_READER: equ 1
PIPE_WRITER: equ 1

extern pipe_new
extern pipe_free
extern pipe_write
extern pipe_read
extern pipe_read_available
extern pipe_write_available

extern pipe_new_obj

%endif