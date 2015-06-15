#ifndef TTY_TTY_OBJ_H
#define TTY_TTY_OBJ_H

#include <sys/types.h>

typedef struct tty_obj_t
{
  unsigned int count;

  int (*read)(struct tty_obj_t* this, void* buf, size_t count);
  int (*write)(struct tty_obj_t* this, void* buf, size_t count);
  int (*close)(struct tty_obj_t* this);

} tty_obj;

tty_obj* tty_obj_new(void);

#endif
