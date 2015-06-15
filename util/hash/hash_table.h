#ifndef UTIL_HASH_HASH_TABLE
#define UTIL_HASH_HASH_TABLE

#include <sys/types.h>

#include <util/list/list.h>

typedef void hash_table;

hash_table* ht_empty();
void ht_free(hash_table* table);

// Adds pair <key, value> to the hash table if it was not added before
void ht_add(hash_table* table, void* key, void* value);
// Removes <key, value> pair from the table if it contains one
void ht_remove(hash_table* table, void* key, void* value);
// Return list of elements such that forall value <- list
// table contains <key, value> pair
list* ht_get(hash_table* table, void* key);

#endif
