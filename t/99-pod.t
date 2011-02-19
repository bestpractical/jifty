use Test::More;
plan skip_all => "Coverage tests only run for authors" unless (-d 'inc/.author');

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

