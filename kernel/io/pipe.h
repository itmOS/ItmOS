#ifndef KERNEL_IO_PIPE_H
#define KERNEL_IO_PIPE_H

#include <sys/types.h>

typedef void pipe_t;

pipe_t* pipe_new(size_t cap);
void pipe_free(pipe_t* pipe);
// Note that all this operations are non-blocking
ssize_t pipe_write(pipe_t* pipe, void* buffer, size_t count);
ssize_t pipe_read(pipe_t* pipe, void* buffer, size_t count);
size_t pipe_read_available(pipe_t* pipe);
size_t pipe_write_available(pipe_t* pipe);

#endif
