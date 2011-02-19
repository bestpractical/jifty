use Test::More;
plan skip_all => "Tab tests only run for authors" unless (-d 'inc/.author');

eval "use Test::NoTabs 1.00";
plan skip_all => "Test::NoTabs 1.00 required for testing POD coverage" if $@;

all_perl_files_ok('lib', 't', 'share');
