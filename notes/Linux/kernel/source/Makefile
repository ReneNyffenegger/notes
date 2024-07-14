
The `Makefile` in the root of the Linux kernel source tree is essentially used to build
  • `→ Linux/kernel/source/vmlinux` (the resident kernel image), and
  • module files
  • documentation (generated in `Documentation/output` from files under `→ Linux/kernel/source/Documentation`)
  • other development related stuff like tag files etc.

The top level `Makefile` → https://github.com/torvalds/linux/blob/e789286468a9ea7acb5aae09a11bdfc7d46874ec/Makefile#L768[includes] `→ Linux/kernel/source/arch/SRCARCH/Makefile` which supplies architecture-specific
information to the top `Makefile`.

{ Version variables #linux-Makefile-version-vars

  The → https://github.com/torvalds/linux/blob/e789286468a9ea7acb5aae09a11bdfc7d46874ec/Makefile#L2-L6[top of the `Makefile`] defines a few version related variables:
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
{ Included files

  table { ll
    `→ Linux/kernel/source/scripts/Kbuild_include` ☰ Definition of *convenience variables* such as `comma`, `quote` etc., *comparison macros* (`test-ge`, `test-lt`) and more such stuff
    `→ Linux/kernel/source/scripts/subarch_include` ☰ Assign value to `SUBARCH`
    `scripts/Makefile.clang` ☰ if `CC_VERSION_TEXT` contains `clang`
    `scripts/Makefile.compiler` ☰ If `need-compiler` is defined
    `arch/$(SRCARCH)/Makefile` ☰ For example `→ Linux/kernel/source/arch/x86/Makefile`
    `→ Linux/kernel/source/include/config/auto_conf` ☰ If `need-config` is defined.
    `scripts/Makefile.extrawarn` ☰
    `scripts/Makefile.debug` ☰ if `CONFIG_DEBUG_INFO` = `y`
    `scripts/Makefile.btf` ☰ if `CONFIG_DEBUG_INFO_BTF` = `y`
    `scripts/Makefile.kasan` ☰ if `CONFIG_KASAN` = `y`
    `scripts/Makefile.kcsan` ☰ if `CONFIG_KCSAN` = `y`
    `scripts/Makefile.kmsan` ☰ if `CONFIG_KMSAN` = `y`
    `scripts/Makefile.ubsan` ☰ if `CONFIG_UBSAN` = `y`
    `scripts/Makefile.kcov` ☰ if `CONFIG_KCOV` = `y`
    `scripts/Makefile.randstruct` ☰ if `CONFIG_RANDSTRUCT` = `y`
    `scripts/Makefile.gcc-plugins` ☰ if `CONFIG_GCC_PLUGINS` = `y`
  table }

}

sa:

  The `Makefile` includes `→ Linux/kernel/source/include/config/auto_conf_cmd`

code {
$ → Linux/kernel/compilation/make [target]
code }

 `Documentation/kbuild/makefiles.rst`

 → Linux/kernel/source

links:
  → https://docs.kernel.org/kbuild/makefiles.html[Linux Kernel Makefiles]

  → https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-2.html[Process of the Linux kernel building]
