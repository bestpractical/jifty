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
            $args->{'_orig_url'} = delete $args->{'url'};
            # XXX mind the existing onclick
            warn 'ooops got original onclick' . Dumper( $args->{onclick} )
                if $args->{onclick};
            $args->{onclick} = {
                region       => $self->region_name,
                replace_with => $url,
                args         => delete $args->{parameters},
            };
        }
	elsif (exists $args->{submit}) {
	    $args->{onclick} = { submit => delete $args->{submit} };
	    $args->{refresh_self} = 1;
	    $args->{as_button} = 1;
	}
        my $onclick = $args->{onclick};
        if ( ref($onclick) eq 'HASH' ) {
            if ( $onclick->{region} && !ref( $onclick->{region} ) ) {
		my $region = $self->region_name;
                $onclick->{region}
                    = $region . '-' . $onclick->{region}
                    unless $onclick->{region} eq $region or $onclick->{region} =~ m/^\Q$region\E-/;
            }
        }
    }
}


1;
