-include Makefile.local

export CC ?= gcc
export CFLAGS = $(EXTRA_CFLAGS) -m32 -Wall -Wextra -std=c99 -ffreestanding

export AS = yasm
export ASFLAGS = $(EXTRA_ASFLAGS) -f elf32 -I $(shell pwd)

export LD = ld
export LDFLAGS = -m elf_i386 -T res/linker.ld

export AR = ar
export ARFLAGS = rcs

# Use qemu by default
EMUL ?= qemu

BOCHS ?= bochs
BOCHSFLAGS ?= -f res/bochsrc -q

QEMU ?= qemu-system-x86_64
QEMUFLAGS ?= -m 1024 -boot d

PARTED ?= parted
PARTEDFLAGS ?= mklabel msdos mkpart primary fat16 2048s 100%
GRUB_MKRESCUE ?= grub-mkrescue
HARD_ROOT ?= hardroot
HARD ?= disk.img
ISO_ROOT ?= isoroot
ISO ?= kernel.iso
OUTPUT_DIR ?= $(ISO_ROOT)/boot
KERNEL ?= $(OUTPUT_DIR)/ItmOS
SUBMODULES ?= boot kernel tty ata interrupts util dev fs multiboot
GRUB_CONF ?= res/grub.cfg

OBJ = $(foreach DIR, $(SUBMODULES), $(DIR)/$(DIR).a)

all: $(HARD)

run: run_$(EMUL)

run_bochs: $(ISO) $(HARD)
	$(BOCHS) $(BOCHSFLAGS)

run_qemu: $(ISO) $(HARD)
	$(QEMU) $(QEMUFLAGS) -cdrom $(ISO) -hda $(HARD)

$(ISO): $(KERNEL)
		-mkdir -p $(ISO_ROOT)/boot/grub
		cp $(GRUB_CONF) $(ISO_ROOT)/boot/grub/grub.cfg
		$(GRUB_MKRESCUE) -o $@ $(ISO_ROOT)

$(HARD): $(KERNEL)
	dd if=/dev/zero of=$(HARD) count=40320
	$(PARTED) $(HARD) $(PARTEDFLAGS)

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
	rm -rf $(HARD) $(HARD_ROOT) $(ISO) $(ISO_ROOT)

.PHONY: all clean $(ISO)
