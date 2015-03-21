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
