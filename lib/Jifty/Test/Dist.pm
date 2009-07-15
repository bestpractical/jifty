package Jifty::Test::Dist;

use FindBin;
use File::Spec;
use Cwd;

our @post_chdir;

BEGIN {
    $Jifty::Test::Dist::OrigCwd = Cwd::cwd;

    @INC = grep { defined } map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;
    chdir "$FindBin::Bin/..";

    # SetupWizard needs this to remove lingering site_config files before
    # loading Jifty
    for (@post_chdir) { $_->() }
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

