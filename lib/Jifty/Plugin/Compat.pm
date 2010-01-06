use strict;
use warnings;

package Jifty::Plugin::Compat;
use base 'Jifty::Plugin';
use Hook::LexWrap;
require Jifty::View::Mason::Handler;

*Jifty::Handler::apache = sub {
    return 'Jifty::Plugin::Compat::Apache';
};

wrap 'Jifty::View::Mason::Handler::new',
    post => sub { my $self = shift;
                  $self->interp->compiler->add_allowed_globals('$r');
                  $self->interp->set_global('$r', 'Jifty::Plugin::Compat::Apache');
              };

package Jifty::Plugin::Compat::Apache;
use Carp;

sub header_in {
    my $class = shift;
    return Jifty->web->request->header(@_);
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

