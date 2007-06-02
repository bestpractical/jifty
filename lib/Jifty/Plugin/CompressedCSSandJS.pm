use strict;
use warnings;

package Jifty::Plugin::CompressedCSSandJS;
use base qw/Jifty::Plugin Class::Accessor/;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

=head1 NAME

Jifty::Plugin::CompressedCSSandJS

=head1 DESCRIPTION

This plugin provides auto-compilation and on-wire compression of your application's CSS and Javascript. It is enabled by default.

=cut

__PACKAGE__->mk_accessors(qw(css js));

sub init {
    my $self = shift;
    my %opt = @_;
    $self->css($opt{css});
    $self->js ($opt{js});
}

sub js_enabled {
    my $self = shift;
    defined $self->js ? $self->js : 1;
}

sub css_enabled {
    my $self = shift;
    defined $self->css ? $self->css : 1;
}

1;
