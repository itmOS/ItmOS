void log_ok(char* message);

void test_register_single(char* name,
                          int (*body)(void));

int simple_c_test(void)
{
    // This test checks nothing, should always pass
    return 0;
}

void c_register_tests(void)
{
    test_register_single("C: simple_c_test", &simple_c_test);
}
