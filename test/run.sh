rm -f notes/.index notes/.last-run

rm -Rf out
mkdir out

go.pl

cp -f ../res/notes.css ../res/q.js out

# TODO: copy files to webserver directory

diff -rq out expected
