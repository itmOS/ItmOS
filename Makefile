-include Makefile.local

export AS = yasm
export ASFLAGS = -f elf32 -I $(shell pwd)

export LD = ld
export LDFLAGS = -m elf_i386 -T res/linker.ld

export AR = ar
export ARFLAGS = rcs

# Use qemu by default
EMUL ?= bochs

BOCHS ?= bochs
BOCHSFLAGS ?= -f res/bochsrc -q

QEMU ?= qemu-system-x86_64
QEMUFLAGS ?= -m 1024

GRUB_MKRESCUE ?= grub-mkrescue
HARD_ROOT ?= hardroot
HARD ?= kernel.img
OUTPUT_DIR ?= $(HARD_ROOT)/boot
KERNEL ?= $(OUTPUT_DIR)/ItmOS
SUBMODULES ?= boot kernel tty interrupts

OBJ = $(foreach DIR, $(SUBMODULES), $(DIR)/$(DIR).a)

all: $(HARD)

run: run_$(EMUL)

run_bochs: $(HARD)
	$(BOCHS) $(BOCHSFLAGS)

run_qemu: $(HARD)
	$(QEMU) $(QEMUFLAGS) -hda $(HARD)

$(HARD): $(KERNEL)
	dd if=/dev/zero of=$(HARD) count=40320
	(echo -n "n\np\n1\n2048\n40319\na\n1\nw\n") | fdisk -C 40 -H 16 -S 63 $(HARD)
	sudo losetup /dev/loop0 $(HARD)
	sudo losetup /dev/loop1 $(HARD) -o 1048576
	sudo mkfs.ext2 /dev/loop1
	sudo mount /dev/loop1 /mnt
	sudo grub-install --root-directory=/mnt --no-floppy --modules="normal part_msdos ext2 multiboot" /dev/loop0
	sync
	sudo cp res/grub.cfg /mnt/boot/grub
	sudo cp $(KERNEL) /mnt/boot
	sync
	sudo losetup -d /dev/loop0
	sudo losetup -d /dev/loop1
	sudo umount /mnt

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
	rm -rf $(HARD) $(HARD_ROOT)

.PHONY: all clean $(ISO)
