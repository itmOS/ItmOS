#include "string.h"
void test_register_single(char* name,
                          int (*body)(void));

int test_strcmp_equals(void) {
    return i_strcmp("abacaba", "abacaba") || i_strcmp("heh", "heh") || i_strcmp("mdachet", "mdachet");
}

int test_strcpy_simple(void) {
    const char* src = "abacaba";
    char dest[20];
    i_strcpy(dest, src);
    return i_strcmp(dest, src);
}

void string_register_tests(void) {
    test_register_single("util/string: strcpy_simple", &test_strcpy_simple);
    test_register_single("util/string: strcmp_equals", &test_strcmp_equals);
}
