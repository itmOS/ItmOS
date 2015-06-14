#ifndef KERNEL_IO_IO_H
#define KERNEL_IO_IO_H

#include "sys/types.h"

// read/write/close functions should be asynchronious and return this
// counstant if they would block
#define IO_WOULD_BLOCK -(1 << 1)
#define IO_READ (1 << 1)
#define IO_WRITE (1 << 2)
#define IO_CLOSE (1 << 3)

// Struct representing some opened file descriptor info
// Pointer to this structure can be shared between several processes
typedef struct fd_obj_t  {
  // Owners counter (like std::shared_ptr)
  int counter;

  // Pointers to the io methods.
  int (*read)(struct fd_obj_t* this, void* buf, size_t count);
  int (*write)(struct fd_obj_t* this, void* buf, size_t count);
  int (*close)(struct fd_obj_t* this);

  // All the rest is the object's private data
  char data[];
} fd_obj;

// events is logical or of the IO_* macros
void io_notify_available(fd_obj* obj, int events);

#endif
