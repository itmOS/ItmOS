#include "string.h"

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

int i_memcmp(const char *fst, const char *snd, unsigned n) {
    unsigned i;
    for (i = 0; i < n && fst[i] == snd[i]; i++);
    return i < n ? fst[i] - snd[i] : 0;
}
