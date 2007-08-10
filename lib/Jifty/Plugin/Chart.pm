use strict;
use warnings;

package Jifty::Plugin::Chart;
use base qw/ Jifty::Plugin Class::Accessor::Fast /;

use Jifty::Plugin::Chart::Web;
use Scalar::Util qw/ blessed /;

__PACKAGE__->mk_accessors(qw/ renderer renderers plugin_args /);

=head1 NAME

Jifty::Plugin::Chart - A charting API for Jifty

=head1 SYNOPSIS

In your F<config.yml>:

  Plugins:
    - Chart: {}

In your Mason templates:

  <% Jifty->web->chart(
      type   => 'Bar',
      width  => 400,
      height => 300,
      data   => [
          [ '2004', '2005', '2006', '2007' ], # labels
          [ 14,     15,     17,     22     ], # first data set
          [ 22,     25,     20,     21     ], # second data set
      ],
  ) %>

=head1 DESCRIPTION

B<CAUTION:> This plugin is experimental. The API I<will> change.

This plugin provides a charting API that can be used by Jifty applications to build data visualizations without regard to the underlying rendering mechanism.

As of this writing, the API is a barely veiled interface over L<Chart>. However, I intend to expand the interface to apply to something like Maani's XML/SWF Charts or Imprise Javascript charts or even something like OpenLaszlo (or something Open Source and Perl if I can find or build such a thing in time).

=head1 INTERFACE

By adding this method to the plugin configuration for your Jifty application, you will cause L<Jifty::Web> to inherit a new method, C<chart>, which is the cornerstone of this API.

This method is described in L<Jifty::Plugin::Chart::Web> and an example is shown in the L</SYNOPSIS> above.

=head1 CONFIGURATION

Here is an example configuration for F<config.yml>:

  Plugins:
    - Chart:
        DefaultRenderer: PlotKit
        PreloadRenderers:
         - XMLSWF
         - SimpleBars
         - App::Renderer::Custom

The available options are:

=over

=item DefaultRenderer

This is the name of the class to use as the default renderer. L<Jifty::Plugin::Chart::Renderer::Chart> is the current default, but that could change in the future. It's recommended that you set this to your preference.

=item PreloadRenderers

This is a list of other render classes to load during initialization. If they are not loaded during initialization some renderers may not work correctly the first time they are run because they are not able to inform Jifty of the CSS or JS files they need before that part of the page is already rendered. If you use the "renderer" option of L<Jifty::Plugin::Chart::Web/chart>, then you should make sure any value you use is set here in the configuration to make sure it works properly.

=back

=head1 METHODS

=head2 init

Adds the L<Jifty::Plugin::Chart::Web/chart> method to L<Jifty::Web>.

=cut

sub init {
    my $self = shift;
    my %args = (
        DefaultRenderer => 'Chart',
        @_,
    );

    # Save the arguments for use in init_renderer() later
    $self->plugin_args( \%args );

    # Deprecating the old form
    if (defined $args{renderer}) {
        warn 'DEPRECATED: renderer argument to Chart plugin is deprecated.'
            .' Use DefaultRenderer instead.';
        $args{DefaultRenderer} = delete $args{renderer};
    }

    # Create the empty renderers list
    $self->renderers({});

    # Pre-load any renderers they plan to use
    if (defined $args{PreloadRenderers}) {
        $args{PreloadRenderers} = [ $args{PreloadRenderers} ]
            unless ref $args{PreloadRenderers};

        for my $renderer (@{ $args{PreloadRenderers} }) {
            $self->init_renderer( $renderer );
        }
    }

    # Load the default renderer
    $self->renderer( $self->init_renderer( $args{DefaultRenderer}, %args ) );

    push @Jifty::Web::ISA, 'Jifty::Plugin::Chart::Web';
}

=head2 init_renderer

  my $renderer = $chart_plugin->init_renderer($renderer_class)

This is a helper method that is used by the API to initialize the renderer class. This is handled automatically so you probably shouldn't use this.

=cut

sub init_renderer {
    my ( $self, $renderer_class ) = ( shift, shift );

    # If it's already an object, just return that
    if ( blessed($renderer_class)
            and $renderer_class->isa(__PACKAGE__.'::Renderer') ) {
        return $renderer_class;
    }

    # Prepend Jifty::Plugin::Chart::Renderer:: if we think we need to
    if ( $renderer_class !~ /::/ ) {
        $renderer_class = __PACKAGE__.'::Renderer::'.$renderer_class;
    }

    # Check to see if we already loaded this one
    my $renderer = $self->renderers->{ $renderer_class };
    return $renderer if defined $renderer;

    # Tell perl to load the class
    $renderer_class->require
        or warn $@;

    # Initialize the renderer
    $renderer = $renderer_class->new( %{ $self->plugin_args } );

    # Remember it
    $self->renderers->{ $renderer_class } = $renderer;

    # Return it!
    return $renderer;
}

=head1 SEE ALSO

L<Jifty::Plugin>, L<Jifty::Web>, L<Jifty::Plugin::Chart::Renderer>, L<Jifty::Plugin::Chart::Renderer::Chart>, L<Jifty::Plugin::Chart::View>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and redistributed under the same terms as Perl itself.

=cut

1;
