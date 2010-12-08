package TestApp::Plugin::SetupWizard::Test;
use Cwd;
BEGIN {
    push @Jifty::Test::Dist::post_chdir, sub { unlink "etc/site_config.yml" };
    unlink "etc/site_config.yml"
        if getcwd =~ /TestApp-Plugin-SetupWizard/;
}

use warnings;
use strict;
use base 'Exporter';

use Jifty::Test::Dist ();
use Jifty::Test::WWW::Mechanize ();

our @EXPORT = qw(site_config_is);

sub import {
    my $class = shift;

    strict->import;
    warnings->import;

    $class->export_to_level(2);

    unshift @_, 'Jifty::Test::Dist';
    my $import = Jifty::Test::Dist->can('import');
    goto $import;
}

sub site_config_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $expected = shift;
    my $name     = shift;

    my $got = eval { Jifty::YAML::LoadFile('etc/site_config.yml') };
    die $@ if $@ && $@ !~ /Cannot read from/ && $@ !~ /is empty or non-existant/; # XXX: sic from YAML::Syck

    Test::More::is_deeply($got, $expected, $name);
}

1;

