package TestApp::Plugin::SetupWizard::Test;
BEGIN { push @Jifty::Test::Dist::post_chdir, sub { unlink "etc/site_config.yml" } }
use warnings;
use strict;
use Jifty::Test::Dist ();
use Jifty::Test::WWW::Mechanize ();

sub import {
    my $class = shift;

    unshift @_, 'Jifty::Test::Dist';
    my $import = Jifty::Test::Dist->can('import');
    goto $import;
}

1;

