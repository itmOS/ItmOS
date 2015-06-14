#ifndef KERNEL_IO_IO_H
#define KERNEL_IO_IO_H

// read/write/close functions should be asynchronious and return this
// counstant if they would block
#define IO_WOULD_BLOCK -(1 << 1)
#define IO_READ (1 << 1)
#define IO_WRITE (1 << 1)
#define IO_CLOSE (1 << 1)

typedef void fd_obj;
// events is logical or of the IO_* macros
void io_notify_available(int events);

#endif
