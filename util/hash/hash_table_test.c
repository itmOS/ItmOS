#include "util/hash/hash_table.h"
#include "util/macro.h"
#include "util/test/common.h"

static void free_list_ptr(list** ptr)
{
  list_free(*ptr);
}

static void free_ht_ptr(hash_table** ptr)
{
  ht_free(*ptr);
}

#define AUTO_HT __attribute__((cleanup(free_ht_ptr))) hash_table*
#define AUTO_LIST __attribute__((cleanup(free_list_ptr))) list*

static int test_simple(void)
{
  AUTO_HT h = ht_empty();
  ASSERT(h);
  ht_add(h, 1, 2);
  ht_add(h, 1, 3);
  {
    AUTO_LIST l = ht_get(h, 1);
    ASSERT(l);
    ASSERT(list_head(l) == 2);
    ASSERT(list_tail(l));
    ASSERT(list_head(list_tail(l)) == 3);
    ASSERT(!list_tail(list_tail(l)));
  }
  ht_add(h, 1, 4);
  {
    AUTO_LIST q = ht_get(h, 1);
    ASSERT(q);
    ASSERT(list_head(q) == 2);
    ASSERT(list_tail(q));
    ASSERT(list_head(list_tail(q)) == 3);
    ASSERT(list_tail(list_tail(q)));
    ASSERT(list_head(list_tail(list_tail(q))) == 4);
    ASSERT(!list_tail(list_tail(list_tail(q))));
  }
  ht_remove(h, 1, 3);
  {
    AUTO_LIST q = ht_get(h, 1);
    ASSERT(q);
    ASSERT(list_head(q) == 2);
    ASSERT(list_tail(q));
    ASSERT(list_head(list_tail(q)) == 4);
    ASSERT(!list_tail(list_tail(q)));
  }
  ht_add(h, 10, 1);
  {
    AUTO_LIST l = ht_get(h, 10);
    ASSERT(l);
    ASSERT(list_head(l) == 1);
    ASSERT(!list_tail(l));
  }
  return 0;
}

void hash_register_tests(void)
{
  test_register_single("UTIL/HASH: simple", &test_simple);
}
