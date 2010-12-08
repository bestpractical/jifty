use strict;
use warnings;

package Jifty::Plugin::Config;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_classdata( after_restart_url => '/' );
__PACKAGE__->mk_classdata( wait_seconds => 5 );
__PACKAGE__->mk_classdata( nav_menu => 1);
__PACKAGE__->mk_classdata( config_url => '/__jifty/config' );
__PACKAGE__->mk_classdata( restart_url => '/__jifty/config/restart.html' );

=head2 NAME

Jifty::Plugin::Config - Add configuration editor

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Config:
        after_restart_url: '/'
        wait_seconds: 5
        config_url: '/__jifty/config'
        restart_url: '/__jifty/config/restart.html'
        nav_menu: 1

=head2  DESCRIPTION

This plugin lets you update etc/config.yml in web page.

=head1 METHODS

=head2 init

set after_restart_url, wait_seconds and config_url, 
default is '/', 5 and '/__jifty/config', respectively
after_restart_url is the url where we will redirect to after restart
wait_seconds are the seconds that we wait for before redirecting
config_url is the url where we will update the config
restart_url is the url where we actually do the restart, with a wait page
setting nav_menu to 0 will stop this plugin from adding anything to your application's navigation menu


=cut

sub init {
    my $self = shift;
    my %opt = @_;
    for ( qw/after_restart_url restart_url config_url wait_seconds nav_menu/ ) {
        __PACKAGE__->$_( $opt{$_} ) if defined $opt{$_};
    }
}

1;

