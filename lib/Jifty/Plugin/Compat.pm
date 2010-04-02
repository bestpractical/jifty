use strict;
use warnings;

package Jifty::Plugin::Compat;
use base 'Jifty::Plugin';
use CGI::Emulate::PSGI ();

=head1 NAME

Jifty::Plugin::Compat - Provide Jifty API compatibility

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Compat: {}

=head1 DESCRIPTION

This plugin provides Jifty API compatibility.

=head2 ConfigVersion VERSION 5

Provides Jifty::Handler->apache for apps prior to ConfigFileVersion 5.

TODO: this should also rebind STDIN/STDOUT in the per-request hook.

=cut

*Jifty::Handler::apache = sub {
    return 'Jifty::Plugin::Compat::Apache';
};

*Jifty::Handler::cgi = sub {
    return 'Jifty::Plugin::Compat::CGI';
};

require Jifty::View::Mason::Handler;
my $old_new = Jifty::View::Mason::Handler->can('new');
no warnings 'redefine';
*Jifty::View::Mason::Handler::new = sub {
    my $self = $old_new->(@_);

    $self->interp->compiler->add_allowed_globals('$r');
    $self->interp->set_global('$r', 'Jifty::Plugin::Compat::Apache');

    return $self;
};

sub wrap {
    my ($self, $app) = @_;

    sub {
        my $env = shift;
        my %cgi = CGI::Emulate::PSGI->emulate_environment($env);
        local *STDIN;
        local %ENV = (%ENV, %cgi);
        $app->($env);
    }
}

push @Jifty::TestServer::ISA, 'Jifty::Server';

package Jifty::Server;

package Jifty::Plugin::Compat::CGI;
use Carp;

sub param {
    my ($class, $key, $val) = @_;
    my $params = Jifty->web->request->parameters;
    if (defined $val) {
        $params->{$key} = $val;
    }
    else {
        return $params->{$key};
    }
}

sub Vars {
    my $params = Jifty->web->request->parameters;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    croak "compat cgi does not handle $AUTOLOAD";
}


package Jifty::Plugin::Compat::Apache;
use Carp;

sub header_in {
    my $class = shift;
    return Jifty->web->request->header(@_);
}

sub headers_in {
    return Jifty->web->request->headers;
}

sub header_out {
    my ($class, $key, $val) = @_;
    if ($key eq 'Status') {
        Jifty->web->response->status( $val );
        return;
    }

    if ($key eq 'Content-Type') {
        Jifty->web->response->content_type( $val );
        return;
    }

    if ($key eq 'Location') {
        Jifty->web->response->status( 302 );
    }

    Jifty->web->response->header( $key, $val );
}

sub headers_out {
    return Jifty->web->response->headers;
}

sub uri {
    my $req = Jifty->web->request;
    return $req->script_name . $req->path_info || '';
}

sub method {
    Jifty->web->request->method;
}

sub content_type {
    my $class = shift;
    Jifty->web->response->content_type( @_ );
}

sub AUTOLOAD {
    our $AUTOLOAD;
    croak "compat apache does not handle $AUTOLOAD";
}

sub params {
    my $class = shift;
    return %{ Jifty->web->request->parameters };
}

1;

