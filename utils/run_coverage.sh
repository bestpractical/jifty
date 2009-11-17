#!/bin/sh
rm -rf cover_db
rm -rf var/mason-cover
make test HARNESS_PERL_SWITCHES='-MDevel::Cover' $@
cover -ignore_re '^var/mason-cover/' -ignore_re '^t/'
egrep -o '(share/[^<]*)' cover_db/coverage.html > cover_db/share-list.txt
find share/html -type f | xargs -n 1 -I% sh -c 'grep -qx % cover_db/share-list.txt || echo %' > cover_db/uncovered-mason.txt
echo "Check cover_db/uncovered-mason.txt for uncovered mason files"

sed -e 's/share\/html//' cover_db/uncovered-mason.txt | xargs -n1 -I% sh -c 'grep -qrw % share/html lib/RT/View* || echo %' > cover_db/uncovered-unseen-mason.txt

echo "Check cover_db/uncovered-unseen-mason.txt for uncovered and unseen mason files"
