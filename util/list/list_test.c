#include "util/list/list.h"
#include "util/test/common.h"
#include "util/macro.h"

static void dump_list(list* l)
{
  while (l) {
    tty_printf("%d -> ", (int) list_head(l));
    l = list_tail(l);
  }
  tty_printf("NULL\n");
}

static int list_test(void)
{
  (void) dump_list; // suppress warnings
  list* l = list_single((void*) 10);
  ASSERT(l);

  ASSERT(list_head(l) == (void*) 10);
  ASSERT(!list_tail(l));
  list* p = list_push(l, (void*) 15);
  ASSERT(p);
  ASSERT(list_head(p) == (void*) 15);
  ASSERT(list_tail(p) == l);
  list* q = list_pop(p);
  ASSERT(q == l);
  ASSERT(list_head(q) == (void*) 10);
  list* w = list_pop(q);
  ASSERT(!w);
  return 0;
}

static int list_test_hard(void)
{
  list* l = NULL;
  for (int i = 0; i < 128; i++) {
    l = list_push(l, (void*) i);
    ASSERT((int) list_head(l) == i);
  }

  list* q = l;
  for (int i = 128; i--;) {
    ASSERT((int) list_head(q) == i);
    q = list_tail(q);
  }

  q = l;
  for (int i = 128; i--;) {
    ASSERT((int) list_head(q) == i);
    q = list_pop(q);
  }

  return 0;
}

void test_register_single(char*, int(*foo)(void));

void list_register_tests(void)
{
  test_register_single("UTIL/LIST: simple", &list_test);
  test_register_single("UTIL/LIST: hard", &list_test_hard);
}
