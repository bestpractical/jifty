use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
plan skip_all => "Coverage tests only run for authors" unless (-d 'inc/.author');
all_pod_files_ok();

