export AS = yasm
export ASFLAGS = -f elf32 -I $(shell pwd)

export LD = ld
export LDFLAGS = -m elf_i386

export AR = ar
export ARFLAGS = rcs

QEMU = qemu-system-x86_64
QEMUFLAGS = -m 1024

KERNEL = ItmOS
SUBMODULES = boot kernel

OBJ = $(foreach DIR, $(SUBMODULES), $(DIR)/$(DIR).a)

all: $(KERNEL)

run: $(KERNEL)
	$(QEMU) $(QEMUFLAGS) -kernel $(KERNEL)

$(KERNEL): $(OBJ)
	$(LD) $(LDFLAGS) $^ -o $@

%.a: FORCE
	@echo "Building $(shell dirname $@)"
	@$(MAKE) --no-print-directory -C $(shell dirname $@)

FORCE:

clean:
	@for dir in $(SUBMODULES) ; do \
		echo "Cleaning $$dir"; \
		$(MAKE) --no-print-directory clean -C $$dir; \
	done
	rm -f $(KERNEL)

.PHONY: all clean
