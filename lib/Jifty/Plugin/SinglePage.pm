use strict;
use warnings;

package Jifty::Plugin::SinglePage;
use base qw/Jifty::Plugin Class::Accessor/;

__PACKAGE__->mk_accessors(qw(region_name));

sub init {
    my $self = shift;
    Jifty::Web::Form::Clickable->add_trigger( before_new => _sp_link($self));
    my %opt = @_;
    $self->region_name($opt{region_name} || '__page');
}

sub _sp_link {
    my $self = shift;
    return sub {
        my ( $clickable, $args ) = @_;
        my $url = $args->{'url'};
        if ( $url && $url !~ m/^#/ ) {
            delete $args->{'url'};

            # XXX mind the existing onclick
            use Data::Dumper;
            warn 'ooops got original onclick' . Dumper( $args->{onclick} )
                if $args->{onclick};
            $args->{onclick} = {
                region       => $self->region_name,
                replace_with => $url,
                args         => delete $args->{parameters}
            };
        }
        my $onclick = $args->{onclick};
        if ( ref($onclick) eq 'HASH' ) {
            if ( $onclick->{region} && !ref( $onclick->{region} ) ) {
                $onclick->{region}
                    = $self->region_name . '-' . $onclick->{region}
                    unless $onclick->{region} =~ m/^__page-/;
            }
        }
    }
}


1;
