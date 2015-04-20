OBJ = mem_manager.o mem_test.o

all: $(OBJ)

list-objs:
	@echo $(foreach O,$(OBJ),$(shell readlink -f $(O)))

clean:
	rm -f $(OBJ)

.PHONY: all clean list-objs
