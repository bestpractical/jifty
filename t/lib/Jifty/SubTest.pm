package Jifty::SubTest;

use FindBin;
use File::Spec;
use Cwd;

BEGIN {
    $Jifty::SubTest::OrigCwd = Cwd::cwd;

    @INC = grep { defined } map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;
    chdir "$FindBin::Bin/..";
}

use lib 'lib';

1;

