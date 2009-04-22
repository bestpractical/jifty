package Jifty::Plugin::RequestInspector;
use strict;
use warnings;
use base 'Jifty::Plugin';
use Time::HiRes 'time';

__PACKAGE__->mk_accessors(qw(url_filter));

my $current_inspection;
my @requests;

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt = @_;
    my $filter = $opt{url_filter} || '.*';
    $self->url_filter(qr/$filter/);

    Jifty::Handler->add_trigger(before_request => sub {
        $self->before_request(@_);
    });

    Jifty::Handler->add_trigger(after_request => sub {
        $self->after_request(@_);
    });
}

sub requests { @requests }

sub get_request {
    my $self = shift;
    my $id   = shift;

    return $requests[$id - 1]; # 1-based
}

sub get_plugin_data {
    my $self   = shift;
    my $id     = shift;
    my $plugin = shift;

    return $self->get_request($id)->{plugin_data}{$plugin};
}

sub new_request_inspection {
    my ($self, $cgi) = @_;

    return {
        id    => 1 + @requests,
        start => time,
        url   => $cgi->url(-absolute => 1, -path_info => 1),
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

    for my $plugin ($self->inspector_plugins) {
        next unless $plugin->can('inspect_before_request');
        my $plugin_data = $plugin->inspect_before_request($cgi);
        $current_inspection->{plugin_data}{ref $plugin} = $plugin_data;
    }
}

sub after_request {
    my ($self, $handler, $cgi) = @_;

    if ($current_inspection) {
        for my $plugin ($self->inspector_plugins) {
            next unless $plugin->can('inspect_after_request');
            my $plugin_data = $current_inspection->{plugin_data}{ref $plugin};
            my $new_plugin_data = $plugin->inspect_after_request($plugin_data, $cgi);
            if (defined($new_plugin_data)) {
                $current_inspection->{plugin_data}{ref $plugin} = $new_plugin_data;
            }
        }
        $current_inspection->{end} = time;
        push @requests, $current_inspection;
    }

    undef $current_inspection;
}

sub should_handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $url = $cgi->url(-absolute => 1, -path_info => 1);

    return $url =~ $self->url_filter;
}

1;

