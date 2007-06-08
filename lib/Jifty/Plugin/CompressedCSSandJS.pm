use strict;
use warnings;

package Jifty::Plugin::CompressedCSSandJS;
use base qw/Jifty::Plugin Class::Accessor/;

=head1 NAME

Jifty::Plugin::CompressedCSSandJS

=head1 DESCRIPTION

This plugin provides auto-compilation and on-wire compression of your application's CSS and Javascript. It is enabled by default.

=cut

__PACKAGE__->mk_accessors(qw(css js));

=head2 init

Initializes the compression object. Takes a paramhash containing keys 'css' and 'js' which can be used to disable compression on files of that type.

=cut

sub init {
    my $self = shift;
    my %opt = @_;
    $self->css($opt{css});
    $self->js ($opt{js});
}

=head2 js_enabled

Returns whether JS compression is enabled (which it is by default)

=cut

sub js_enabled {
    my $self = shift;
    defined $self->js ? $self->js : 1;
}

=head2 css_enabled

Returns whether CSS compression is enabled (which it is by default)

=cut

sub css_enabled {
    my $self = shift;
    defined $self->css ? $self->css : 1;
}

1;
