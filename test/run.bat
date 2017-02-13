@rem @rmdir /s /q out
@rem @mkdir out



rmdir /s /q  %rn_root%test\notes

@..\scripts\create-html.pl

@copy /y ..\res\notes.css %rn_root%test\notes > nul
@copy /y ..\res\q.js      %rn_root%test\notes > nul

@rmdir /s /q \tools\UniServerZ\www\notes

@xcopy /s /e /i %rn_root%test\notes \tools\UniServerZ\www\notes > nul

@echo .
@echo .
@echo .
@del %rn_root%test\notes\.index
@rem @c:\tools\cygwin\bin\diff -rq %rn_root%test\notes expected
@diff -rq %rn_root%test\notes expected
