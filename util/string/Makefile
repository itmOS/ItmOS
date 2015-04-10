OUTPUT = string.a
OBJ = string.o string_test.o

export CFLAGS = -m32 -Wall -Wextra -std=c99

all: $(OUTPUT)

list-objs:
	@echo $(foreach O,$(OBJ),$(shell readlink -f $(O)))

$(OUTPUT): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

clean:
	rm -f $(OBJ) $(OUTPUT)

.PHONY: all clean
