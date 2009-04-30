use strict;
use warnings;

package Jifty::Plugin::Config;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_classdata( after_restart_url => '/' );
__PACKAGE__->mk_classdata( wait_seconds => 5 );

=head2 NAME

Jifty::Plugin::Config - Add configuration editor

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Config:
        after_restart_url: '/'
        wait_seconds: 5

=head2  DESCRIPTION

This plugin lets you update etc/config.yml in web page.

=head1 METHODS

=head2 init

set after_restart_url and wait_seconds, default is '/' and 5, respectively
after_restart_url is the url we will redirect to after restart
wait_seconds are the seconds that we wait for before redirecting

=cut

sub init {
    my $self = shift;
    my %opt = @_;
    if ( $opt{after_restart_url} ) {
        __PACKAGE__->after_restart_url( $opt{after_restart_url} );
    }
    if ( $opt{wait_seconds} ) {
        __PACKAGE__->wait_seconds( $opt{wait_seconds} );
    }
}

1;

