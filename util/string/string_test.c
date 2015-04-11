#include "i_string.h"
void test_register_single(char* name,
                          int (*body)(void));

int test_strcmp_equals(void) {
    return i_strcmp("abacaba", "abacaba") || i_strcmp("heh", "heh") || i_strcmp("mdachet", "mdachet");
}

int test_strcmp_greater(void) {
    return i_strcmp("hello", "hallo") <= 0 || i_strcmp("hello", "hell") <= 0; 
}

int test_strcmp_lesser(void) {
    return i_strcmp("123", "23") >= 0 || i_strcmp("12","123") >= 0;
}

int test_strcpy(const char* src) {
    char dest[150];
    i_strcpy(dest, src);
    return i_strcmp(dest, src);
}

int test_strcpy_simple(void) {
    return test_strcpy("abacaba");
}

int test_strcpy_hard(void) {
    return test_strcpy("qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOP{}|ASDFGHJKL:ZXCVBNM<>?");
}

void string_register_tests(void) {
    test_register_single("UTIL/STRING: strcpy_simple", &test_strcpy_simple);
    test_register_single("UTIL/STRING: strcpy_hard", &test_strcpy_hard);
    test_register_single("UTIL/STRING: strcmp_equals", &test_strcmp_equals);
    test_register_single("UTIL/STRING: strcmp_greater", &test_strcmp_greater);
    test_register_single("UTIL/STRING: strcmp_lesser", &test_strcmp_lesser);
}
