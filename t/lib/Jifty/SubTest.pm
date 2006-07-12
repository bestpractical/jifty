package Jifty::SubTest;

use FindBin;
use Cwd;
BEGIN {
    @INC = map { ref($_) ? $_ : Cwd::abs_path($_) } @INC;
    chdir "$FindBin::Bin/..";
}

use lib 'lib';

1;

