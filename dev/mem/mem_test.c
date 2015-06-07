
void test_register_single(char* name, int (*body)(void));
unsigned int begin_page;
unsigned int page_count;
unsigned int memory_map;


int test_mem_map_loaded(void) {
	if (begin_page != 0)
		return 0;
	else
		return -1;
}

int test_mem_map_free_pages(void) {
	if (page_count != 0)
		return 0;
	else
		return -1;
}


void mem_register_tests(void) {
	test_register_single("UTIL/MEM: memory_map_loaded", &test_mem_map_loaded);
	test_register_single("UTIL/MEM: memory_map_free_pages", &test_mem_map_free_pages);
}
