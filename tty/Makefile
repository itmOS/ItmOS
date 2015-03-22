OUTPUT = tty.a
OBJ = tty.o

all: $(OUTPUT)

$(OUTPUT): $(OBJ)
	$(AR) $(ARFLAGS) $@ $<

clean:
	rm -f $(OBJ) $(OUTPUT)

.PHONY: all clean
