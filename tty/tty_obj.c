#include "tty/tty_obj.h"

extern void tty_printf(char* fmt, ...);

#include <stdlib.h>

static int read(tty_obj* this, void* buf, size_t count)
{
  (void) this;
  (void) buf;
  (void) count;
  return 0;
}

static int write(tty_obj* this, void* buf, size_t count)
{
  (void) this;
  // FIXME: Wow such vulnerable
  char local[count + 1];
  local[count] = 0;
  for (size_t i = count; i--;) {
    local[i] = ((char*) buf)[i];
  }
  local[count] = 0;
  tty_printf("%s", local);
  return count;
}

static int close(tty_obj* this)
{
  --this->count;
  if (this->count == 0) {
    free(this);
  }
  return 0;
}

tty_obj* tty_obj_new(void)
{
  tty_obj* result = malloc(sizeof(tty_obj));
  result->read = read;
  result->write = write;
  result->close = close;
  return result;
}
