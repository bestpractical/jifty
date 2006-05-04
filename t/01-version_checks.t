#!/usr/bin/perl -w
use strict;
use Test::More qw(no_plan);

use ExtUtils::MakeMaker;
use_ok('Jifty::Everything');
my @files = grep({$_ !~ m#^/#} map({$INC{$_}} grep(/^Jifty\//, keys(%INC))));
ok(scalar(@files));

foreach my $file (@files) {
	# Gah! parse_version complains on stderr!
	my ($e, @a) = error_catch(sub {MM->parse_version($file)});
	ok(($e || '') eq '', $file) or warn "$e ";
}

# runs subroutine reference, looking for error message $look in STDERR
# and runs tests based on $name
#   ($errs, @ans) = error_catch(sub {$this->test()});
#
sub error_catch {
	my ($sub) = @_;
	my $TO_ERR;
	open($TO_ERR, '<&STDERR');
	close(STDERR);
	my $catch;
	open(STDERR, '>', \$catch);
	my @ans = $sub->();
	open(STDERR, ">&", $TO_ERR);
	close($TO_ERR);
	return($catch, @ans);
} # end subroutine error_catch definition
########################################################################
