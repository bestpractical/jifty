use strict;
use warnings;

package Jifty::Plugin::SinglePage;
use base 'Jifty::Plugin';

__PACKAGE__->mk_accessors(qw(region_name));

=head1 NAME

Jifty::Plugin::SinglePage

=head1 DESCRIPTION

Makes your normal Jifty app into a single-page app through clever use of regions

=head2 init

Registers a before_new trigger to modify links and sets up the special region

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;

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
        if ( $url && $url !~ m/^#/ && $url !~ m{^https?://} && $url !~ m{^javascript:} ) {
            $self->_push_onclick($args, {
                region       => $self->region_name,
                replace_with => $url,
                args         => $args->{parameters}});
        }
        elsif (exists $args->{submit} && !$args->{onclick}) {
	    if ($args->{_form} && $args->{_form}{submit_to}) {
		my $to = $args->{_form}{submit_to};
		$self->_push_onclick($args, { beforeclick => qq{return _sp_submit_form(this, event, "$to");} });
	    }
	    else {
		$self->_push_onclick($args, { refresh_self => 1, submit => $args->{submit} });
	    }
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
