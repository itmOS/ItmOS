#ifndef UTIL_LIST_H
#define UTIL_LIST_H

typedef struct
{
  struct list* next;
  void* data;
} list;

list* list_single(void*);
void* list_head(list*);
list* list_tail(list*);
void list_free(list*);
list* list_push(list*, void*);
list* list_pop(list*);

#endif
