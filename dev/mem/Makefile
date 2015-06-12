OBJ = phymem.o virtmem.o mem_test.o pagetable.o kernel_allocation.o

all: $(OBJ)

list-objs:
	@echo $(foreach O,$(OBJ),$(shell readlink -f $(O)))

clean:
	rm -f $(OBJ)

.PHONY: all clean list-objs
