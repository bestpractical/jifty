package t::Jifty;
use Test::Base -Base;
BEGIN { $ENV{'JIFTY_VENDOR_CONFIG'} = 't/test_config.yml' }
use Jifty::Everything;


filters {
    form        => [qw< yaml request_from_webform >],
    request     => [qw< yaml >],
};

package t::Jifty::Filter;
use Test::Base::Filter -Base;


sub request_from_webform {
    my $form = shift;
    my $r = Jifty::Request->new->from_webform(%$form);
    delete $r->{$_} for qw(env headers parameters cookies scheme);
    return $r;
}

