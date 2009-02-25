use strict;
use warnings;

package Jifty::Plugin::GoogleMap;
use base qw/Jifty::Plugin Class::Accessor::Fast/;


=head1 NAME

Jifty::Plugin::GoogleMap - GoogleMap plugin

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - GoogleMap:
        apikey: ABQIAAAA66LEkTHjdh-UhDZ_NkfdjBTb-vLQlFZmc2N8bgWI8YDPp5FEVBTjCfxPSocuJ53SPMNQDO7Sywpp_w

Note that this is an api for http://localhost:8888/ -- you will need
to provide your own API key for your own site.


In your model class schema description, add the following:

    column location => is GeoLocation;


=head1 DESCRIPTION

This plugin provides a Google-map widget for Jifty, as well as a new GeoLocation column type.

=cut

__PACKAGE__->mk_accessors(qw(apikey));

=head2 init

=cut

sub init {
    my $self = shift;
    my %opt  = @_;
    $self->apikey( $opt{apikey} );
    Jifty->web->add_external_javascript("http://maps.google.com/maps?file=api&v=2&key=".$self->apikey);
    Jifty->web->add_javascript(qw( google_map.js ) );
    Jifty->web->add_css('google_map.css');
}

sub _geolocation {
    my ($column, $from) = @_;
    my $name = $column->name;
    $column->virtual(1);
    $column->container(1);
    for (qw(x y)) {
        Jifty::DBI::Schema::_init_column_for(
            Jifty::DBI::Column->new({ type => 'double precision',
                                      name => $name."_$_",
                                      render_as => 'hidden',
                                      writable => $column->writable,
                                      readable => $column->readable }),
            $from);
    }
    no strict 'refs';
    *{$from.'::'.$name} = sub { return { map { my $method = "${name}_$_"; $_ => $_[0]->$method } qw(x y) } };
    *{$from.'::'.'set_'.$name} = sub { die "not yet" };
}

use Jifty::DBI::Schema;
Jifty::DBI::Schema->register_types(
    GeoLocation =>
        sub { _init_handler is \&_geolocation, render_as 'Jifty::Plugin::GoogleMap::Widget' },
);


1;
