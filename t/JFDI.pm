package t::JFDI;
use Test::Base -Base;
BEGIN { $ENV{'JFDI_VENDOR_CONFIG'} = 't/test_config.yml' }
use JFDI::Everything;

filters {
    form        => [qw< yaml request_from_webform >],
    request     => [qw< yaml >],
};

package t::JFDI::Filter;
use Test::Base::Filter -Base;


sub request_from_webform {
    my $form = shift;
    JFDI::Request->new->from_webform(%$form);
}

