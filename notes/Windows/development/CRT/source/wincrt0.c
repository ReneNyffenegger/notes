$ Windows CRT: wincrt0

Apparently, this compilation unit is responsible of calling `WinMain()` after performing C Run-Time initialization.

It defines the → development/languages/C-C-plus-plus/preprocessor/macros[macro] `_WINMAIN_` and then `#include`s → Windows/development/CRT/source/crt0_c[`crt0.c`].

