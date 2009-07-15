package TestApp::Plugin::SetupWizard::Test;
use Cwd;
BEGIN {
    push @Jifty::Test::Dist::post_chdir, sub { unlink "etc/site_config.yml" };
    unlink "etc/site_config.yml"
        if getcwd =~ /TestApp-Plugin-SetupWizard/;
}

use warnings;
use strict;
use Jifty::Test::Dist ();
use Jifty::Test::WWW::Mechanize ();

sub import {
    my $class = shift;

    strict->import;
    warnings->import;

    unshift @_, 'Jifty::Test::Dist';
    my $import = Jifty::Test::Dist->can('import');
    goto $import;
}

1;

