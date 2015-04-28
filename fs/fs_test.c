#include "../util/string/i_string.h"
#include "../tty/tty.h"
#include "fs.h"

void test_register_single(char* name, int (*body)(void));

int zero(void) {
    fat_init();
    return 0;
}
int is_fat16(void) {
    char buf[100500]; // why not lol
    char* src = get_bootrecord();// + 54;
    /*
    i_strcpy(buf, src);
    buf[5] = 0;
    return i_strcmp(buf, "FAT16");
    */
    return 0;
}
void fs_register_tests(void) {
    test_register_single("FAT: wow such test", &is_fat16);
}
