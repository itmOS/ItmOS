OUTPUT = main.a
OBJ = main.o

all: $(OUTPUT)

list-objs:
	@echo $(foreach O,$(OBJ),$(shell readlink -f $(O)))

$(OUTPUT): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

clean:
	rm -f $(OBJ) $(OUTPUT)

.PHONY: all clean
