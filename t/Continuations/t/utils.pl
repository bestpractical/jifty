use lib '../../lib';

BEGIN { 
    $ENV{'JIFTY_VENDOR_CONFIG'} = 't/test_config.yml';
    
    # This needs to happen before the handle is created, so it can't happen in
    # BTDT::Test->setup_test
    system("JIFTY_VENDOR_CONFIG=t/test_config.yml bin/jifty schema --install --create --force ."); 
}

use Jifty::Everything;
use Jifty::Server;

1;
