use strict;
use warnings;

package Jifty::Plugin::Prototypism;
use base 'Jifty::Plugin';

=head1 NAME

Jifty::Plugin::Prototypism - Provide Prototype and Scriptaculous js libraries

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Prototypism
        cdn: 'http://yourcdn.for.static.prefix/'

=head1 DESCRIPTION

This module provides the Prototype and Scriptaculous javascript
libraries to your application.  Jifty used to rely on these libraries,
so this plugin may be automatically added to your application's
plugins if you upgrade from an older version of Jifty.  It is safe to
remove if your application does not use Prototype or Scriptaculous
javascript code, however.

=cut

__PACKAGE__->mk_accessors(qw/cdn/);

=head1 METHODS

=head2 init

On initialization, adds Jifty compatibility methods if the
configuration file version is before 4.

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt  = @_;
    $self->cdn( $opt{ cdn } || '' );
    my @js = qw!
        prototype
        scriptaculous/builder
        scriptaculous/effects
        scriptaculous/controls
    !;

    push @js, 'jifty_compatible' if Jifty->config->framework('ConfigFileVersion') < 4;
    Jifty->web->add_javascript( "prototypism/$_.js" ) for @js;

}

1;

