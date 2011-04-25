use strict;
use warnings;

package Jifty::Plugin::SinglePage;
use base 'Jifty::Plugin';

__PACKAGE__->mk_accessors(qw/region_name/);

our $NO_SPA;

=head1 NAME

Jifty::Plugin::SinglePage - Makes your app into a single-page

=head1 DESCRIPTION

Makes your normal Jifty app into a single-page app through clever use of regions

=head1 METHODS

=head2 init

Registers a before_new trigger to modify links and sets up the special region

=cut

Jifty->web->add_javascript(
    'singlepage/rsh/rsh.js',
    'singlepage/spa.js'
);

sub init {
    my $self = shift;
    return if $self->_pre_init;

    Jifty::Web::Form::Clickable->add_trigger( before_new => _sp_link($self));
    Jifty::Web::Form::Clickable->add_trigger( name      => 'before_state_variable',
                                              callback  => _filter_page_region_vars($self),
                                              abortable => 1 );
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

sub _filter_page_region_vars {
    my $self = shift;
    return sub {
        return if $NO_SPA;
        my ( $clickable, $key, $value ) = @_;
        if ($key eq 'region-'.$self->region_name || $key =~ m/^region-\Q$self->{region_name}\E\./) {
            return 0;
        }
        return 1;
    }
}

sub _sp_link {
    my $self = shift;
    return sub {
        return if $NO_SPA;
        return if Jifty->web->temporary_current_user; # for LetMe
        my ( $clickable, $args ) = @_;
        my $url = $args->{'url'};
        if ( $url && $url !~ m/^#/ && $url !~ m{^https?://} && $url !~ m{^javascript:} ) {
            my $complete_url = $url.'?'.Jifty->web->query_string(%{$args->{parameters}});
            $complete_url =~ s/\?$//;
            $self->_push_onclick($args, {
                region       => $self->region_name,
                replace_with => $url,
                beforeclick  => qq{SPA.historyChange('$complete_url', { 'continuation':{}, 'actions':{}, 'fragments':[{'mode':'Replace','args':@{[ Jifty::JSON::encode_json($args->{parameters})]},'region':'__page','path':'$url'}],'action_arguments':{}}, true);},
                args         => { %{$args->{parameters}}} });
        }
        elsif (exists $args->{submit} && !$args->{onclick}) {
            if ($args->{_form} && $args->{_form}{submit_to}) {
                my $to = $args->{_form}{submit_to};
                $self->_push_onclick($args, { beforeclick => qq{return SPA._sp_submit_form(this, event, "$to");} });
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
