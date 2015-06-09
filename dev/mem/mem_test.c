
void test_register_single(char* name, int (*body)(void));
void put_pages(void* addr, int len);
void* get_pages(int len);
unsigned int begin_page;


int test_mem_map_loaded(void) {
	if (begin_page != 0)
		return 0;
	else
		return -1;
}

int test_get_pages(void) {
	void* a = get_pages(1);
	put_pages(a, 1);
	void* b = get_pages(1);
	if (a != 0 && a == b)
		return 0;
	return -1;
}

void mem_register_tests(void) {
	test_register_single("DEV/MEM: memory_map_loaded", &test_mem_map_loaded);
	test_register_single("DEV/MEM: get_an_put", &test_get_pages);
}
