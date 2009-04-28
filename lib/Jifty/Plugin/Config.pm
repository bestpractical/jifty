use strict;
use warnings;

package Jifty::Plugin::Config;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_classdata( 'after_restart_url' );

=head2 NAME

Jifty::Plugin::Config - Add configuration editor

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Config:
        after_restart_url: '/'

=head2  DESCRIPTION

This plugin provides a basic configuration editor for your application.
Basically, it tries to help you update the most important items in Jifty's config
file, so you don't need to edit the config file directly.

the updated config file will be saved in file $EVN{JIFTY_SITE_CONFIG} or
etc/site_config.yml

=head1 METHODS

=head2 init

set after_restart_url, default is '/'

=cut

sub init {
    my $self = shift;
    my %opt = @_;
    if ( $opt{after_restart_url} ) {
        __PACKAGE__->after_restart_url( $opt{after_restart_url} || '/' );
    }
}

1;

