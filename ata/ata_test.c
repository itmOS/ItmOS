#include <string.h>
#include "ata.h"

void test_register_single(char* name,
                          int (*body)(void));


int ata_simple_read_test(void) {
    char data[600];
    memset(data, 0, sizeof(data));
    strcpy(data, "success");
    strcpy(data + 300, "another success");
    ata_wr_segs(200, 2, data);
    char data2[600];
    memset(data2, 0, sizeof(data));
    ata_rd_segs(200, 2, data2);
    return strcmp(data, data2) || strcmp(data + 300, data2 + 300);
}

void ata_register_tests(void) {
    test_register_single("ATA PIO: simple rd/wr", &ata_simple_read_test);
}
