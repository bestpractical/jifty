use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer;

=head1 NAME

Jifty::Plugin::Chart::Renderer - Base class for chart rendering classes

=head1 SYNOPSIS

In your F<config.yml>:

  Plugins:
    - Chart:
        renderer: MyApp::Renderer;

In F<lib/MyApp/Renderer.pm>:

  package MyApp::Renderer;
  use base qw/ Jifty::Plugin::Chart::Renderer /;

  sub init {
      my $self = shift;

      # Handle any required initialization, like required CSS, JS, etc.
  }

  sub render {
      my $self = shift;
      my %args = @_;

      # Output your chart
      Jifty->web->out( #{ Output your chart here... } );

      # You could also return it as a string...
      return;
  }

=head1 METHODS

Your renderer implementation must subclass this package and implement the following methods:

=head2 new

This is the constructor. Don't override this directly. Instead implement L</init>.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init;
    return $self;
}

=head2 init

  $renderer->init();

This is called by C<new> immediately after constructing the object. Subclasses should implement this method to do any required initialization such as letting Jifty know about required CSS files, JS files, etc.

=cut

sub init {}

=head2 render

  Jifty->web->out($renderer->render(%args));

See L<Jifty::Plugin::Chart::Web> for the arguments. It must (at least) accept the arguments given to the L<Jifty::Plugin::Chart::Web/chart> method.

The C<render> method may either return it's output or print it out using L<Jifty::Web::out>.

=cut

sub render {}

=head1 SEE ALSO

L<Jifty::Plugin::Chart::Web>, L<Jifty::Plugin::Chart::Renderer::Chart>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
