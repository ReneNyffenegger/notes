$ scripts/kconfig/Makefile

`scripts/kconfig/Makefile` implements → Linux/kernel/compilation/make#linux-make-config-targets[make targets related to kernel configuration].
-
When invoking `→ Linux/kernel/compilation/make` with one of these targets, the target name is mapped to the corresponding option name of `→ Linux/kernel/source/scripts/kconfig/conf`.

{ KCONFIG_DEFCONFIG_LIST

  If `cross_compiling` is not defined, the `Makefile` adds the following files to `KCONFIG_DEFCONFIG_LIST`:
    • `/lib/modules/$(kernel-release)/.config`
    • `/etc/kernel-config`
    • `/boot/config-$(kernel-release)`

  Additionally, it adds the file `→ Linux/kernel/source/arch/SRCARCH/configs[arch/$SRCARCH/configs]/$(KBUILD_DEFCONFIG)` to this list.

}

sa:

 `→ Linux/kernel/source/scripts/kconfig`
