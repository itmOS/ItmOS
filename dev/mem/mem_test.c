void tty_printf(char* fmt, ...);

void test_register_single(char* name, int (*body)(void));
void put_pages(void* addr, int len);
void* get_pages(int len);
void* begin_page;


int test_mem_map_loaded(void) {
	//tty_printf("Begin page: %d\n", begin_page);
	if (begin_page != 0)
		return 0;
	else
		return -1;
}

int test_get_pages(void) {
	void* a = get_pages(1);
	put_pages(a, 1);
	void* b = get_pages(1);
	//tty_printf("Begin page: %d\n", begin_page);
	//tty_printf("Simple put&get: %d %d\n", a, b);
	if (a != 0 && a == b)
		return 0;
	return -1;
}

int test_get_pages_hard(void) {
	//tty_printf("Begin page: %d\n", begin_page);
	void* a = get_pages(2);
	//tty_printf("Begin page: %d\n", begin_page);
	void* b = a + 4096;
	put_pages(b, 1);
	//tty_printf("Begin page: %d\n", begin_page);
	void* c = get_pages(1);
	//tty_printf("Begin page: %d\n", begin_page);
	//tty_printf("Hard put&get: %d %d %d \n", a, b, c);
	if (a != 0 &&  b != 0 && c != 0 && b == c)
		return 0;
	
	return -1;
}


int test_get_pages_hard2(void) {
	void* a = get_pages(2);
	void* b = a + 4096;
	put_pages(b, 1);
	put_pages(a, 1);
	void* c = get_pages(2);
	//tty_printf("Begin page: %d\n", begin_page);
	//tty_printf("Hard put&get2: %d %d %d \n", a, b, c);
	if (a != 0 &&  b != 0 && c != 0 && a == c)
		return 0;
	
	return -1;
}

int test_get_pages_hard3(void) {
	int amount = 0;
	void* old_begin = begin_page;
	while (get_pages(1)) {
		amount++;
	}
	void* a = old_begin + 4096 * (amount - 1);
	put_pages(a, 1);
	put_pages(a - 4096, 1);

	void* b = get_pages(2);

	//tty_printf("Hard put&get3: %d %d \n", a, b);
	if ((a - 4096) != b || a == 0 || b == 0)
		return -1;

	put_pages(a, 1);
	put_pages(a - 4096, 1);
	
	put_pages(old_begin, 1);
	void* c = get_pages(1);
	void* d = get_pages(2);

	//tty_printf("Hard put&get3: %d %d\n", c, d);
	if (c == 0 || c != old_begin || d == 0 || d != (a - 4096))
		return -1;

	put_pages(old_begin, amount);

	void* e = get_pages(1);
	//tty_printf("Hard put&get3: %d \n", e);

	if (e == 0 || e != (old_begin + (amount - 1) * 4096))
		return -1;

	put_pages(e, 1);
	
	return 0;
}



void mem_register_tests(void) {
	test_register_single("DEV/MEM: memory_map_loaded", &test_mem_map_loaded);
	test_register_single("DEV/MEM: get_and_put", &test_get_pages);
	test_register_single("DEV/MEM: get_and_put_hard", &test_get_pages_hard);
	test_register_single("DEV/MEM: get_and_put_hard v2", &test_get_pages_hard2);
	test_register_single("DEV/MEM: get_and_put_hard v3", &test_get_pages_hard3);
}
