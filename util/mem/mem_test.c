
void test_register_single(char* name, int (*body)(void));
unsigned int memory_map;


int test_mem_map_loaded(void) {
	if (memory_map != 0)
		return 0;
	else
		return -1;
}


void mem_register_tests(void) {
	test_register_single("UTIL/MEM: memory_map_loaded", &test_mem_map_loaded);
}