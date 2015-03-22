ItmOS
=======================================

A simple operating system written entirely in assembly by the ITMO University students.

Building
--------
To build a bootable iso image use:
```
make
```

You will need "grub2" to be installed with support of the multiboot kernels.
Also may need to install the "xorriso" utility to be installed (or the "libisoburn" package if your distro repos does not contains xorriso).

Running
-------
If you prefer qemu use (make will build kernel if not already):
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
For example if you want to select version of grub-mkrescue utility
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
