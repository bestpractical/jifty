#!/bin/sh
rm -rf cover_db
rm -rf var/mason-cover
make test HARNESS_PERL_SWITCHES='-MDevel::Cover' $@
cover -ignore_re '^var/mason-cover/' -ignore_re '^t/'
egrep -o '(share/[^<]*)' cover_db/coverage.html > cover_db/share-list.txt
find share/html -type f | xargs -n 1 -I% sh -c 'grep -qx % cover_db/share-list.txt || echo %' > cover_db/uncovered-mason.txt
echo "Check cover_db/uncovered-mason.txt for uncovered mason files"

