#!/usr/bin/env perl -w
use strict;
use Test::More qw(no_plan);

# by Eric Wilhelm in response to Randal Schwartz pointing out that
# CPAN.pm chokes on the VERSION >... construct
# I dare not mention it here.

use ExtUtils::MakeMaker;
use_ok('Jifty::Everything');

# XXX there may be a more cross-platform and harness-friendly way to say
# this.  Tricky bit is that the harness absolutifies the lib paths or
# plans to chdir() somewhere.

# just look for Jifty.pm
my $dir = $INC{'Jifty.pm'};
$dir =~ s/Jifty\.pm$//;
$dir = quotemeta $dir;  # as MSWin32 has backslashes in the path
my @files = grep({$_ and $_ =~ m/^$dir/} map({$INC{$_}} grep(/^Jifty\//, keys(%INC))));
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
