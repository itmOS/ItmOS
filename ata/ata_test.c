#include "../util/string/i_string.h"
#include "../tty/tty.h"
#include "ata.h"

void test_register_single(char* name,
                          int (*body)(void));

#define BUF_SIZE 2048
char buf1[BUF_SIZE];
char buf2[BUF_SIZE];

int ata_test_1(int lba, const char *str) {
    i_memset(buf1, 0, BUF_SIZE);
    i_strcpy(buf1, str);
    ata_wr_segs(lba, 1, buf1);
    i_memset(buf2, 0, BUF_SIZE);
    ata_rd_segs(lba, 1, buf2);
    return i_strcmp(buf1, buf2);
}

int ata_test_2(int lba, const char *str1, const char *str2) {
    i_memset(buf1, 0, BUF_SIZE);
    i_strcpy(buf1, str1);
    i_strcpy(buf1 + 256, str2);
    ata_wr_segs(lba, 2, buf1);
    i_memset(buf2, 0, BUF_SIZE);
    ata_rd_segs(lba, 2, buf2);
    return i_strcmp(buf1, buf2) || i_strcmp(buf1 + 256, buf2 + 256);
}

int ata_simple_read_test(void) {
    return ata_test_1(400, "success") || ata_test_1(600, "yes") || ata_test_1(800, "mdachet");
}

int ata_complex_read_test(void) {
    return ata_test_2(400, "success", "yes") || ata_test_2(600, "abacaba", "babacaba") || ata_test_2(838, "hehehajajajaja1231231222", "hahalahahaha"); 
}

void ata_register_tests(void) {
    test_register_single("ATA PIO: simple rd/wr", &ata_simple_read_test);
    test_register_single("ATA PIO: complex rd/wr", &ata_complex_read_test);
}
