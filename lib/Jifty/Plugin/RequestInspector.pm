package Jifty::Plugin::RequestInspector;
use base qw/Jifty::Plugin/;
use strict;
use warnings;

my $current_inspection;
my @requests;

sub init {
    my $self = shift;
    return if $self->_pre_init;

    Jifty::Handler->add_trigger(before_request => sub {
        $self->before_request(@_);
    });

    Jifty::Handler->add_trigger(after_request => sub {
        $self->after_request(@_);
    });
}

sub new_request_inspection {
    my ($self, $cgi) = @_;

    return {
        id   => 1 + @requests,
        time => DateTime->now,
        url  => $cgi->url(-absolute => 1, -path_info => 1),
    };
}

do {
    my $inspector_plugins;
    sub inspector_plugins {
        if (!defined($inspector_plugins)) {
            $inspector_plugins = [
                grep {
                    $_->can('inspect_before_request') ||
                    $_->can('inspect_after_request')
                } Jifty->plugins
            ];
        }
        return @$inspector_plugins;
    }
};

sub before_request {
    my ($self, $handler, $cgi) = @_;

    return unless $self->should_handle_request($cgi);

    $current_inspection = $self->new_request_inspection($cgi);
    push @requests, $current_inspection;

    for my $plugin ($self->inspector_plugins) {
        next unless $plugin->can('inspect_before_request');
        my $plugin_data = $plugin->inspect_before_request($cgi);
        $current_inspection->{plugin_data}{$plugin->name} = $plugin_data;
    }
}

sub after_request {
    my ($self, $handler, $cgi) = @_;

    if ($current_inspection) {
        for my $plugin ($self->inspector_plugins) {
            next unless $plugin->can('inspect_after_request');
            my $plugin_data = $current_inspection->{plugin_data}{$plugin->name};
            $plugin->inspect_after_request($plugin_data, $cgi);
        }
    }

    undef $current_inspection;
}

sub should_handle_request {
    return 1;
}

1;

