#include "util/test/common.h"
#include "util/macro.h"
#include "util/string/i_string.h"

#include "kernel/io/pipe.h"

static int test_simple(void)
{
  fd_obj* objs[2];
  i_memset(objs, 0, sizeof objs);
  pipe_obj_new(objs);
  ASSERT(objs[0]);
  ASSERT(objs[1]);
  char* s = "Hello, World\n";
  int len = i_strlen(s) + 1;
  char buffer[256];
  ASSERT(len == (objs[1]->write(objs[1], s, len)));
  ASSERT(len == (objs[0]->read(objs[0], buffer, len)));
  ASSERT(i_strcmp(buffer, s) == 0);
  return 0;
}

void pipe_obj_register_tests(void)
{
  test_register_single("KERNEL/IO/PIPE: fd_obj", &test_simple);
}
