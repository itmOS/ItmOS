OBJ = phymem.o virtmem.o mem_test.o pagetable.o sbrk.o

all: $(OBJ)

list-objs:
	@echo $(foreach O,$(OBJ),$(shell readlink -f $(O)))

clean:
	rm -f $(OBJ)

.PHONY: all clean list-objs
