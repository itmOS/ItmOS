#include "../util/string/i_string.h"
#include "../tty/tty.h"
#include "ata.h"

void test_register_single(char* name,
                          int (*body)(void));


int ata_simple_read_test(void) {
    char data[260];
    i_memset(data, 0, 256);
    i_strcpy(data, "success");
    tty_printf(data);
    ata_wr_segs(600, 1, data);
    tty_printf(data);
    char data2[260];
    i_memset(data2, 0, 256);
    __asm("xchg %bx, %bx");
    ata_rd_segs(600, 1, data2);
    tty_printf(data);
    return i_strcmp(data, data2);
}

void ata_register_tests(void) {
    test_register_single("ATA PIO: simple rd/wr", &ata_simple_read_test);
}
