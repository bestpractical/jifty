#!/usr/bin/env perl
package Jifty::Test::WWW::Declare;
use strict;
use warnings;
use base qw/Exporter/;

# Sub::Exporter doesn't warn about redefining functions, which we do in the
# import routine below
use Sub::Exporter -setup => {
    -as => 'export_subs',
    exports => ['get'],
};

BEGIN { require Jifty::Test; require Test::WWW::Declare }

our @EXPORT = qw/$server $URL/;

our $server;
our $URL;

sub import
{
    my $class = shift;

    # set up database and other things
    Jifty::Test->import(@_);

    # export the DSL-ey functions
    Test::WWW::Declare->export_to_level(2);

    # Note that these next exports must come AFTER T:W:D->export because we
    # override parts of it

    # Exporter: $server and $URL
    __PACKAGE__->export_to_level(1);

    # Sub::Exporter: get()
    __PACKAGE__->export_subs({ into_level => 1 }, 'get');

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

