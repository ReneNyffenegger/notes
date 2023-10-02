$ arch/x86/Makefile

{ BITS

 `arch/x86/Makefile` → https://github.com/torvalds/linux/blob/8f1b4600373f9da2afc124f31788b16f47eb950c/arch/x86/Makefile#L58-L61[defines the variable `BITS`] as
 «an extension for files which are available in a 32 and 64-bit version to simplify shared Makefiles».

  The value of `BITS` is set to 32 if `CONFIG_X86_32` set, otherwise, it is set to 64.

  Examples of source files that come in two versions are
    • `→ Linux/kernel/source/arch/x86/boot/compressed/head_32_S` and `→ Linux/kernel/source/arch/x86/boot/compressed/head_64_S`
    • `→ Linux/kernel/source/arch/x86/entry/entry_32_S` and `→ Linux/kernel/source/arch/x86/entry/entry_64_S`

 `BITS` is also used to set the compiler option `-m32` or `-m64`.

} 
