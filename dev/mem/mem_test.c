void tty_printf(char* fmt, ...);

void test_register_single(char* name, int (*body)(void));
void put_pages(void* addr, int len);
void* get_pages(int len);
unsigned int begin_page;


int test_mem_map_loaded(void) {
	tty_printf("Begin page: %d\n", begin_page);
	if (begin_page != 0)
		return 0;
	else
		return -1;
}

int test_get_pages(void) {
	void* a = get_pages(1);
	put_pages(a, 1);
	void* b = get_pages(1);
	tty_printf("Simple put&get: %d %d\n", a, b);
	if (a != 0 && a == b)
		return 0;
	return -1;
}

int test_get_pages_hard(void) {
	void* a = get_pages(2);
	void* b = a + 4096;
	put_pages(b, 1);
	void* c = get_pages(1);
	tty_printf("Hard put&get: %d %d %d \n", a, b, c);
	if (a != 0 &&  b != 0 && c != 0 && b == c)
		return 0;
	
	return -1;
}


void mem_register_tests(void) {
	test_register_single("DEV/MEM: memory_map_loaded", &test_mem_map_loaded);
	test_register_single("DEV/MEM: get_and_put", &test_get_pages);
	test_register_single("DEV/MEM: get_and_put2", &test_get_pages_hard);
}
