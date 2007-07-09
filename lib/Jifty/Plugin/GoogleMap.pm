use strict;
use warnings;

package Jifty::Plugin::GoogleMap;
use base qw/Jifty::Plugin Class::Accessor::Fast/;


=head1 NAME

Jifty::Plugin::GoogleMap

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - GoogleMap:
        apikey: ABQIAAAA66LEkTHjdh-UhDZ_NkfdjBTb-vLQlFZmc2N8bgWI8YDPp5FEVBTjCfxPSocuJ53SPMNQDO7Sywpp_w

# note that this is an api for http://localhost:8888/

=head1 DESCRIPTION

This plugin provides auto-compilation and on-wire compression of your
application's CSS and Javascript. It is enabled by default, unless
your C<ConfigFileVersion> is greater or equal than 2.

It also supports js minifier, you will need to specify the full path.
The jsmin can be obtained from
L<http://www.crockford.com/javascript/jsmin.html>.

Note that you will need to use C<ConfigFileVersion> 2 to be able to
configure jsmin feature.

=cut

__PACKAGE__->mk_accessors(qw(apikey));

=head2 init

Initializes the compression object. Takes a paramhash containing keys
'css' and 'js' which can be used to disable compression on files of
that type.

=cut

sub init {
    my $self = shift;
    my %opt  = @_;
    $self->apikey( $opt{apikey} );
    Jifty->web->external_javascript_libs(["http://maps.google.com/maps?file=api&v=2&key=".$self->apikey]);
    Jifty->web->add_javascript(qw( google_map.js ) );
}

sub _geolocation {
    my ($column, $from) = @_;
    my $name = $column->name;
    $column->virtual(1);
    $column->container(1);
    for (qw(x y)) {
        Jifty::DBI::Schema::_init_column_for(
            Jifty::DBI::Column->new({ type => 'double',
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
