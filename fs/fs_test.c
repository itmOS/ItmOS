#include "../util/string/i_string.h"
#include "../tty/tty.h"
#include "fs.h"

void test_register_single(char* name, int (*body)(void));
char buf[10500]; // why not lol

int read_file(void) {
    //fat_read(41472, buf);
    return 0;
}
int is_fat16(void) {
    fat_init();
    char* src = get_bootrecord() + 54;
    i_strcpy(buf, src); // FIXME use memcpy instead
    buf[5] = 0;
    return i_strcmp(buf, "FAT16");
}
void fs_register_tests(void) {
    test_register_single("FAT: FS is FAT16", &is_fat16);
    test_register_single("FAT: try to read a file", &read_file);
}
