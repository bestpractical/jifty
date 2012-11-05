use strict;
use warnings;

package Jifty::Plugin::PubSub::Subscriptions;

# This is _new rather than new because it is a singleton
sub _new {
    my $class = shift;
    my $env = shift;

    my $self = bless {
        store       => {},
        client_id   => undef,
    }, $class;
    return $self;
}

sub reset {
    my $self = shift;
    $self->{client_id} = undef;
}

sub retrieve {
    my $self = shift;
    my $client_id = shift;
    return delete $self->{store}{$client_id} || [];
}

sub client_id {
    my $self = shift;
    return $self->{client_id};
}

sub clear_for {
    my $self = shift;
    my ($region) = @_;
    return unless $self->{client_id};
    $self->{store}{$self->{client_id}} = [
        grep { not exists $_->{region} or $_->{region} ne $region }
            @{$self->{store}{$self->{client_id}} }
        ];
}

sub add {
    my $self = shift;
    my %args = (
        topic              => undef,
        region             => undef,
        path               => undef,
        arguments          => undef,
        mode               => undef,
        element            => undef,
        effect             => undef,
        effect_args        => undef,
        remove_effect      => undef,
        remove_effect_args => undef,
        @_
    );

    $self->{client_id} ||= "jifty_" . Jifty->web->serial;

    delete $args{$_} for grep {not defined $args{$_}} keys %args;

    $args{attrs}{$_} = delete $args{$_}
        for grep {defined $args{$_}}
            qw/       effect        effect_args
               remove_effect remove_effect_args/;

    push @{$self->{store}{$self->{client_id}}}, \%args;
}

sub update_on {
    my $self = shift;
    my $region = Jifty->web->current_region;
    unless ($region) {
        warn "Jifty->subs->update_on called when not in a region";
        return;
    }

    my %args = %{ $region->arguments };
    delete $args{region};
    delete $args{event};
    $self->add(
        arguments => \%args,
        mode      => 'Replace',
        region    => $region->qualified_name,
        path      => $region->path,
        @_,
    );
}

1;
