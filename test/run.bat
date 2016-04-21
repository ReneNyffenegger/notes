del notes\.index
del notes\.last-run

rmdir /s /q out
mkdir out

go.pl

copy /y ..\res\notes.css out

rmdir /s /q \tools\UniServerZ\www\notes

xcopy /s /e /i out \tools\UniServerZ\www\notes

diff -r out expected
