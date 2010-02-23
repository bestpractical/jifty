#!/usr/bin/env perl
package Jifty::Test::WWW::Declare;
use strict;
use warnings;
use base qw(Exporter);
BEGIN { require Jifty::Test; require Test::WWW::Declare }

our @EXPORT = qw($server $URL get);

our $server;
our $URL;

sub import
{
    my $class = shift;

    # set up database and other things
    Jifty::Test->import(@_);

    # export the DSL-ey functions
    Test::WWW::Declare->export_to_level(2);

    # export $server, $URL, and whatever else J:T:W:D adds
    # note that this must come AFTER T:W:D->export because we override some
    # of its functions
    no warnings 'redefine';
    __PACKAGE__->export_to_level(1);

    # create a server (which will be automatically exported)
    $server = Jifty::Test->make_server;
    $URL = $server->started_ok;
}

=head1 NAME

Jifty::Test::WWW::Declare - Subclass of L<Test::WWW::Declare> with
extra Jifty features

=head1 SYNOPSIS

    use Jifty::Test::WWW::Declare tests => 2;

    session user => run {
        flow 'login page' => check {
            get 'login';
            content should match qr{Email:};
            content should match qr{Password:};
        };
    };

=head1 FUNCTIONS

=head2 get PATH

Automatically prepend the server's URL to the PATH. You may avoid this by
specifying the full URL yourself (it checks for C</^http/>).

=cut

sub get
{
    my $url = shift;
    $url = "$URL/$url"
        unless $url =~ /^http/;

    Test::WWW::Declare::get($url);
}

1;

