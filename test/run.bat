@del  notes\.index     > nul
@del  notes\.last-run  > nul

@rmdir /s /q out
@mkdir out

@go.pl

@copy /y ..\res\notes.css out > nul
@copy /y ..\res\q.js      out > nul

@rmdir /s /q \tools\UniServerZ\www\notes

@xcopy /s /e /i out \tools\UniServerZ\www\notes > nul

@echo .
@echo .
@echo .

@diff -rq out expected
