package Jifty::Test::Dist;

use FindBin;
use File::Spec;
use Cwd;

BEGIN {
    $Jifty::Test::Dist::OrigCwd = Cwd::cwd;

    @INC = grep { defined } map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;
    chdir "$FindBin::Bin/..";
}

use lib 'lib';
use base qw/Jifty::Test/;

=head1 NAME

Jifty::Test::Dist - Tests in Jifty distributions inside of Jifty

=head1 SYNOPSIS

    use Jifty::Test::Dist tests => 5;

=head1 DESCRIPTION

Jifty::Test::Dist is a utility wrapper around L<Jifty::Test>; it
changes the current working directory to be the one step above where
the test file is, so that Jifty will detect the correct application
root for the tests.

=cut

1;

