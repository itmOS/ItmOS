-include Makefile.local

export AS = yasm
export ASFLAGS = -f elf32 -I $(shell pwd)

export LD = ld
export LDFLAGS = -m elf_i386 -T res/linker.ld

export AR = ar
export ARFLAGS = rcs

# Use qemu by default
EMUL ?= qemu

BOCHS ?= bochs
BOCHSFLAGS ?= -f res/bochsrc -q

QEMU ?= qemu-system-x86_64
QEMUFLAGS ?= -m 1024

GRUB_MKRESCUE ?= grub-mkrescue
ISO_ROOT ?= isoroot
ISO ?= kernel.iso
OUTPUT_DIR ?= $(ISO_ROOT)/boot
KERNEL ?= $(OUTPUT_DIR)/ItmOS
SUBMODULES ?= boot kernel tty ata

OBJ = $(foreach DIR, $(SUBMODULES), $(DIR)/$(DIR).a)

all: $(ISO)

run: run_$(EMUL)

run_bochs: $(ISO)
	$(BOCHS) $(BOCHSFLAGS)

run_qemu: $(ISO)
	$(QEMU) $(QEMUFLAGS) -cdrom $(ISO)

$(ISO): $(KERNEL)
	-mkdir -p $(ISO_ROOT)/boot/grub
	cp res/grub.cfg $(ISO_ROOT)/boot/grub
	$(GRUB_MKRESCUE) -o $@ $(ISO_ROOT)

$(KERNEL): $(OBJ)
	-mkdir -p $(OUTPUT_DIR)
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
	rm -rf $(ISO) $(ISO_ROOT)

.PHONY: all clean $(ISO)
