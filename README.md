ItmOS
=====

A simple operating system written entirely in assembly by the ITMO University students.

Building
--------
To build a bootable iso image, run:
```
make
```

You will need "grub2" to be installed with support of the multiboot kernels.
Also may need to install the "xorriso" utility (or the "libisoburn" package if your distro repos do not contain xorriso).

Running
-------
If you prefer qemu, use (make will build kernel if not already):
```
make run
```

if you prefer bochs, use:
```
make EMUL=bochs run
```

Custom make settings
--------------------
You can redefine almost all settings for the building and running process.
For example if you want to select the version of grub-mkrescue utility
there are two ways to do this, first:
```
make GRUB_MKRESCUE=grub2-mkrescue all
```
or create file named "Makefile.local"
and set the variable there:
```
GRUB_MKRESCUE = grub2-mkrescue
```
Above is true for many other variables, for example "EMUL", "SUBMODULES", "OUTPUT_DIR" etc.

FAQ
---
Q: I have "xorriso : FAILURE : Cannot find path '/efi.img' in loaded ISO image" message when trying to run "make run"
A: Probably you have ArchLinux and it have some strange problems with it. Create file "Makefile.local" and add "GRUB_MKRESCUE = grub-mkrescue -d /usr/lib/grub/i386-pc" line to it.
