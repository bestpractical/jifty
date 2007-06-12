package Jifty::SubTest;

use FindBin;
use File::Spec;
BEGIN {
    @INC = grep { defined } map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;
    $0 = File::Spec->rel2abs($0);
    chdir "$FindBin::Bin/..";
}

use lib 'lib';

1;

