#ifndef I_STRING_H
#define I_STRING_H
__attribute__((cdecl))
void i_strcpy(char *dst, const char *src); 
int i_strcmp(const char *fir, const char *snd);
void i_memset(void *ptr, int value, int num);
#endif
