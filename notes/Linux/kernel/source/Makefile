
The `Makefile` in the root of the Linux kernel source tree is essentially used to build
  • vmlinux (the resident kernel image), and
  • module files
  • documentation
  • other development related stuff like tag files etc.

code {
$ → Linux/kernel/compilation/make …
code }

{ Version variables #linux-Makefile-version-vars

  The → https://github.com/torvalds/linux/blob/master/Makefile#L2-L6[top of the `Makefile`] defines a few version related variables:
code {
VERSION = 6
PATCHLEVEL = 5
SUBLEVEL = 0
EXTRAVERSION = -rc7
NAME = Hurr durr I'ma ninja sloth
code }

code {
$ → Linux/kernel/compilation/make -s kernelversion
6.5.0-rc7
code }

  Compare with `include/config/kernel.release` (if it exists) and
 `include/generated/uapi/linux/version.h` (if it exists).

}

sa:

 `Documentation/kbuild/makefiles.rst`

  → Linux/kernel/source

links:
  → https://docs.kernel.org/kbuild/makefiles.html[Linux Kernel Makefiles]

  → https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-2.html[Process of the Linux kernel building]

