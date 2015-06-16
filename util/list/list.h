#ifndef UTIL_LIST_H
#define UTIL_LIST_H

typedef void* list;

list* list_single(void*);
void* list_head(list*);
// Get tail without freeing the list
list* list_tail(list*);
// Free all list
void list_free(list*);
list* list_push(list*, void*);
// Get tail and free the current head
list* list_pop(list*);

#endif
