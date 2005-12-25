use Test::More;
eval "use Test::Pod::Coverage 1.00";
die $@ if $@;
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

my %skips  = map  { $_ => 1 } qw( Jifty::JSON Jifty::JSON::Converter Jifty::JSON::Parser);
my @files  = grep { not exists $skips{$_} } Test::Pod::Coverage::all_modules();

plan tests => scalar @files;

Test::Pod::Coverage::pod_coverage_ok( $_, { nonwhitespace => 1 } )
	for @files;

# Workaround for dumb bug (fixed in 5.8.7) where Test::Builder thinks that
# certain "die"s that happen inside evals are not actually inside evals,
# because caller() is broken if you turn on $^P like Module::Refresh does
#
# (I mean, if we've gotten to this line, then clearly the test didn't die, no?)
Test::Builder->new->{Test_Died} = 0;
