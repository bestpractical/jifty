package Jifty::Plugin::RequestInspector;
use strict;
use warnings;
use base 'Jifty::Plugin';
use Time::HiRes 'time';

sub version { '0.0.2' }

__PACKAGE__->mk_accessors(qw(url_filter on_cookie persistent));

my $current_inspection;
my @requests;

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt = (
        url_filter => '.*',
        on_cookie  => undef,
        persistent => 0,
        @_
    );

    $self->url_filter(qr/$opt{url_filter}/);
    $self->on_cookie($opt{on_cookie});
    $self->persistent($opt{persistent});

    Jifty::Handler->add_trigger(before_request => sub {
        $self->before_request(@_);
    });

    Jifty::Handler->add_trigger(after_request => sub {
        $self->after_request(@_);
    });
}

sub requests {
    my $self = shift;
    my %args = (
        after => 0,
        @_,
    );

    if ($self->persistent) {
        my $requests = Jifty::Plugin::RequestInspector::Model::RequestCollection->new(
            current_user => Jifty->app_class('CurrentUser')->superuser
        );
        $requests->unlimit;
        $requests->limit( column => "id", operator => ">", value => $args{after}) if $args{after};
        return map { {%{$_->data}, id => $_->id} } @{$requests->items_array_ref};
    } else {
        return @requests[$args{after}..$#requests];
    }
}

sub get_request {
    my $self = shift;
    my $id   = shift;

    if ($self->persistent) {
        my $req = Jifty::Plugin::RequestInspector::Model::Request->new(
            current_user => Jifty->app_class('CurrentUser')->superuser
        );
        $req->load( $id );
        return undef unless $req->id;
        return { %{$req->data}, id => $req->id };
    } else {
        return $requests[$id - 1]; # 1-based
    }
}

sub add_request {
    my $self = shift;

    return unless $current_inspection;

    if ($self->persistent) {
        my $req = Jifty::Plugin::RequestInspector::Model::Request->new(
            current_user => Jifty->app_class('CurrentUser')->superuser
        );
        my ($ok, $msg) = $req->create(
            data => $current_inspection
        );
    } else {
        push @requests, $current_inspection;
        $requests[-1]{id} = scalar @requests;
    }
}

sub clear_requests {
    my $self = shift;

    if ($self->persistent) {
        Jifty->handle->simple_query( "DELETE FROM ".Jifty::Plugin::RequestInspector::Model::Request->table );
    } else {
        @requests = ();
    }
    undef $current_inspection;
}

sub last_id {
    my $self = shift;
    if ($self->persistent) {
        return Jifty->handle->fetch_result( "SELECT MAX(id) FROM ". Jifty::Plugin::RequestInspector::Model::Request->table );
    } else {
        return scalar @requests;
    }
}

sub get_plugin_data {
    my $self   = shift;
    my $id     = shift;
    my $plugin = shift;

    return $self->get_request($id)->{plugin_data}{$plugin};
}

sub new_request_inspection {
    my ($self, $cgi) = @_;

    my $ret = {
        start => time,
        url   => $cgi->url(-absolute => 1, -path_info => 1),
    };

    if (my $cookie_name = $self->on_cookie) {
        my %cookies     = CGI::Cookie->fetch();
        $ret->{cookie} = $cookies{$cookie_name}->value;
    }
    return $ret;
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
        for my $plugin (reverse $self->inspector_plugins) {
            next unless $plugin->can('inspect_after_request');
            my $plugin_data = $current_inspection->{plugin_data}{ref $plugin};
            my $new_plugin_data = $plugin->inspect_after_request($plugin_data, $cgi);
            if (defined($new_plugin_data)) {
                $current_inspection->{plugin_data}{ref $plugin} = $new_plugin_data;
            }
        }
        $current_inspection->{end} = time;
        $self->add_request;
    }

    undef $current_inspection;
}

sub should_handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $url = $cgi->url(-absolute => 1, -path_info => 1);
    return unless $url =~ $self->url_filter;

    if (my $cookie_name = $self->on_cookie) {
        my %cookies     = CGI::Cookie->fetch();
        return unless $cookies{$cookie_name};
    }

    return 1;
}

1;

__END__

=head1 NAME

Jifty::Plugin::RequestInspector - Inspect requests

=head1 DESCRIPTION

Do not use this plugin directly. Other plugins use this plugin.

=head1 METHODS

=head2 init

Sets up hooks into the request cycle.

=head2 before_request

Hooks into the request cycle to forward "request is beginning" and more
metadata to RequestInspector plugins.

=head2 after_request

Hooks into the request cycle to forward "request is done" and more metadata
to RequestInspector plugins.

=head2 clear_requests

Clears the list of request inspections.

=head2 get_plugin_data RequestID, Plugin::Name

Returns the B<opaque> plugin data for a particular request ID and plugin class
name.

=head2 get_request RequestID

Returns all data for a particular request ID.

=head2 requests

Returns a list of all inspections for all requests.

=head2 inspector_plugins

Returns a list of plugin instances that hook into RequestInspector.

=head2 new_request_inspection

Instantiates a new request inspection, setting up some defalt values.

=head2 should_handle_request CGI

Decides whether the request described by the CGI parameter should be handled,
based on plugin configuration.

=cut

