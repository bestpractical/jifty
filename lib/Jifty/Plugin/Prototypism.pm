use strict;
use warnings;

package Jifty::Plugin::Prototypism;
use base 'Jifty::Plugin';

=head1 NAME

Jifty::Plugin::Prototypism

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Prototypism
        cdn: 'http://yourcdn.for.static.prefix/'

=cut

__PACKAGE__->mk_accessors(qw(cdn));

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt  = @_;
    $self->cdn( $opt{ cdn } || '' );
    my @js = qw(
        prototype
        scriptaculous/builder
        scriptaculous/effects
        scriptaculous/controls
    );

    Jifty->web->add_javascript( "prototypism/$_.js" ) for @js;

}

1;

