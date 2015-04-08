OUTPUT = c.a
OBJ = register_tests.o

export CFLAGS = -m32 -Wall -Wextra -std=c99

all: $(OUTPUT)

$(OUTPUT): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

clean:
	rm -f $(OBJ) $(OUTPUT)

.PHONY: all clean
