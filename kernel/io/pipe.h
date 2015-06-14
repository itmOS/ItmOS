#ifndef KERNEL_IO_PIPE_H
#define KERNEL_IO_PIPE_H

#include <sys/types.h>

#include "kernel/io/io.h"

typedef void pipe_t;

#define PIPE_READER 1
#define PIPE_WRITER 2

typedef struct pipe_obj_t
{
  unsigned int count;

  int (*read)(struct pipe_obj_t* this, void* buf, size_t count);
  int (*write)(struct pipe_obj_t* this, void* buf, size_t count);
  int (*close)(struct pipe_obj_t* this);

  pipe_t* pipe;
  // PIPE_READER or PIPE_WRITER
  int which_end;
} pipe_obj;

// Allocate new fd_objs with the pipe inside
void pipe_obj_new(fd_obj* res[2]);

pipe_t* pipe_new(size_t cap);
void pipe_free(pipe_t* pipe);
// Note that all this operations are non-blocking
ssize_t pipe_write(pipe_t* pipe, void* buffer, size_t count);
ssize_t pipe_read(pipe_t* pipe, void* buffer, size_t count);
size_t pipe_read_available(pipe_t* pipe);
size_t pipe_write_available(pipe_t* pipe);

#endif
