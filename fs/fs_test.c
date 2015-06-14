#include "../util/string/i_string.h"
#include "../tty/tty.h"
#include "fs.h"

void test_register_single(char* name, int (*body)(void));
char buf[10500]; // why not lol

struct fdobject* mda;

int open_file(void) {
    //mda = fat_open("LIPSUM  TXT", 0);
    mda = fat_open("HELLO   TXT", 0);
    return !mda;
}

int read_file(void) {
    if (mda) {
        int l = mda->read(mda, buf, 0);
        if (l < 0)
            return l;
        //tty_printf(buf);
        return 0;
    }
    return -1;
}

int is_fat16(void) {
    fat_init();
    char* src = get_bootrecord() + 54;
    return i_memcmp(src, "FAT16", 5);
}
void fs_register_tests(void) {
    test_register_single("FAT: FS is FAT16", &is_fat16);
    test_register_single("FAT: try to open a file", &open_file);
    test_register_single("FAT: try to read a file", &read_file);
}
