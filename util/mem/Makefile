OBJ = mem_manager.o

all: $(OBJ)

list-objs:
	@echo $(foreach O,$(OBJ),$(shell readlink -f $(O)))

clean:
	rm -f $(OBJ)

.PHONY: all clean list-objs
