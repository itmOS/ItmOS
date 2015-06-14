#include "kernel/io/pipe.h"

#include "util/test/common.h"
#include "util/macro.h"
#include "util/string/i_string.h"
#include "util/random/random.h"

typedef struct
{
  size_t cap;
  size_t head;
  size_t tail;
  char start[];
} pipe_real;

static int test_simple(void)
{

  char* S = "Hello, World\n";
  int S_n = i_strlen(S);

  __attribute__((cleanup(pipe_free))) pipe_t* pipe = pipe_new(20);

  char buffer[256];
  pipe_write(pipe, (void*) S, S_n + 1);
  pipe_read(pipe, (void*) buffer, S_n + 1);

  ASSERT(i_strcmp(buffer, S) == 0);

  return 0;
}

#define HARD_LEN 1000
char buffer[HARD_LEN];
char result[HARD_LEN];

static int test_hard(void)
{
  size_t CAP = 20;

  __attribute__((cleanup(pipe_free))) pipe_t* pipe = pipe_new(CAP);
  ASSERT(pipe_read_available(pipe) == 0);
  ASSERT(pipe_write_available(pipe) == CAP);

  for (size_t i = HARD_LEN; i--;) {
    buffer[i] = (unsigned char) rand();
  }

  pipe_real* _pipe = (pipe_real*) pipe;
  size_t r_i = 0;
  size_t w_i = 0;
  while (r_i < HARD_LEN) {
    ssize_t wrote = pipe_write(pipe, buffer + w_i, HARD_LEN - w_i);
    w_i += wrote;
    ssize_t read = pipe_read(pipe, result + r_i, HARD_LEN - r_i);
    r_i += read;
  }

  for (size_t i = HARD_LEN; i--;) {
    ASSERT(buffer[i] == result[i]);
  }

  return 0;
}

void pipe_register_tests(void)
{
  test_register_single("KERNEL/IO/PIPE: simple", &test_simple);
  test_register_single("KERNEL/IO/PIPE: hard", &test_hard);
}
