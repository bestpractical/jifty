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

sub _push_onclick {
    my $self = shift;
    my $args = shift;
    $args->{onclick} = [ $args->{onclick} ? $args->{onclick} : () ]
        unless ref $args->{onclick} eq 'ARRAY';
    push @{$args->{onclick}}, @_ if @_;
}

sub _sp_link {
    my $self = shift;
    return sub {
        my ( $clickable, $args ) = @_;
        my $url = $args->{'url'};
        if ( $url && $url !~ m/^#/ && $url !~ m{^https?://} ) {
            # XXX mind the existing onclick
            $self->_push_onclick($args, {
                region       => $self->region_name,
                replace_with => $url,
                args         => delete $args->{parameters}});
        }
        elsif (exists $args->{submit}) {
	    $self->_push_onclick($args, { refresh_self => 1, submit => delete $args->{submit} });
	    $args->{as_button} = 1;
	}
        if (my $form = delete $args->{_form}) {
	    $args->{call} = $form->call;
	}
        my $onclick = $args->{onclick};
        if ( $args->{onclick} ) {
            $self->_push_onclick($args);    # make sure it's array
            for my $onclick ( @{ $args->{onclick} } ) {
                next unless UNIVERSAL::isa($onclick, 'HASH');
                if ( $onclick->{region} && !ref( $onclick->{region} ) ) {
                    my $region = $self->region_name;
                    $onclick->{region} = $region . '-' . $onclick->{region}
                        unless $onclick->{region} eq $region
                        or $onclick->{region} =~ m/^\Q$region\E-/;
                }
            }
        }
    }
}


1;
