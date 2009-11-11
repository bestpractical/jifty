#!/bin/sh
rm -rf cover_db
rm -rf var/mason-cover
make test HARNESS_PERL_SWITCHES='-MDevel::Cover' $@
cover -ignore_re '^var/mason-cover/' -ignore_re '^t/'
