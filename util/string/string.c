#include "string.h"

void i_strcpy(char *dest, char *src) {
    while ((*dest++ = *src++));
}

int i_strcmp(char *fst, char *snd) {
    while (*fst != '\0' && *snd != '\0' && *fst++ == *snd++);
    return *fst - *snd;
}

void i_memset(void *ptr, int value, int num) {
    char *char_ptr = (char *) ptr;
    for (int i = 0; i < num; i++) {
        char_ptr[i] = value;
    }
}
