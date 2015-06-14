#include "i_string.h"

void i_strcpy(char *dest, const char *src) {
    while ((*dest++ = *src++));
}

int i_strcmp(const char *fst, const char *snd) {
    while (*fst && *fst == *snd)
        fst++, snd++;
    return *fst - *snd;
}

void i_memset(void *ptr, int value, int num) {
    unsigned char *char_ptr = ptr;
    while (num--)
        *char_ptr++ = (unsigned char) value;
}

int i_strlen(const char* s)
{
  int res = 0;
  while (*s) {
    ++res;
    ++s;
  }
  return res;
}
