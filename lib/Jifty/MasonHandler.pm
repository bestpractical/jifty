package Jifty::MasonHandler;

# XXX ALEX: CLEAN UP AND DOC THIS

use strict;
use warnings;

use HTML::Mason;
use HTML::Mason::Utils;
use CGI;
use File::Spec;
use Params::Validate qw(:all);
use HTML::Mason::Exceptions;
use HTML::Mason::FakeApache;

use Class::Container;
use base qw(Class::Container);

use HTML::Mason::MethodMaker
    ( read_write => [ qw( interp ) ] );

use vars qw($VERSION);

__PACKAGE__->valid_params
    (
     interp => { isa => 'HTML::Mason::Interp' },
     cgi => { isa => 'CGI' },
    );

__PACKAGE__->contained_objects
    (
     interp => 'HTML::Mason::Interp',
     cgi_request => { class   => 'HTML::Mason::FakeApache', # $r
                      delayed => 1 },
    );


sub new {
    my $package = shift;

    my %p = @_;
    my $self = $package->SUPER::new(comp_root => $ENV{DOCUMENT_ROOT},
                                    request_class => 'HTML::Mason::Request::Jifty',
                                    error_mode => 'output',
                                    error_format => 'html',
                                    %p);

    $self->interp->compiler->add_allowed_globals('$r');
    
    return $self;
}

sub handle_comp {
    my ($self, $comp) = (shift, shift);

    my $r = $self->create_delayed_object('cgi_request', cgi => $self->{cgi});
    $self->interp->set_global('$r', $r);

    # hack for testing
    $self->interp->delayed_object_params('request', cgi_request => $r);

    my %args = $self->request_args($r);

    my @result;
    if (wantarray) {
        @result = eval { $self->interp->exec($comp, %args) };
    } elsif ( defined wantarray ) {
        $result[0] = eval { $self->interp->exec($comp, %args) };
    } else {
        eval { $self->interp->exec($comp, %args) };
    }

    if (my $err = $@) {
        my $retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value  :
                     isa_mason_exception($err, 'Decline') ? $err->declined_value :
                     rethrow_exception $err;

        # Unlike under mod_perl, we cannot simply return a 301 or 302
        # status and let Apache send headers, we need to explicitly
        # send this header ourself.
        $r->send_http_header if $retval && grep { $retval eq $_ } ( 200, 301, 302 );

        return $retval;
    }

    return wantarray ? @result : defined wantarray ? $result[0] : undef;
}

sub request_args {
    return %{Jifty->web->request->arguments};
}


###########################################################
package HTML::Mason::Request::Jifty;
# Subclass for HTML::Mason::Request object $m

use HTML::Mason::Exceptions;
use HTML::Mason::Request;
use base qw(HTML::Mason::Request);

use Params::Validate qw(BOOLEAN);
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

__PACKAGE__->valid_params
    ( cgi_request => { isa => 'HTML::Mason::FakeApache' } );

use HTML::Mason::MethodMaker
    ( read_only  => [ 'cgi_request' ] );

sub auto_send_headers {
    return not Jifty->web->request->is_subrequest;
}

sub exec
{
    my $self = shift;
    my $r = $self->cgi_request;
    my $retval;

    eval { $retval = $self->SUPER::exec(@_) };

    if (my $err = $@)
    {
	$retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value  :
                  isa_mason_exception($err, 'Decline') ? $err->declined_value :
                  rethrow_exception $err;
    }

    # On a success code, send headers if they have not been sent and
    # if we are the top-level request. Since the out_method sends
    # headers, this will typically only apply after $m->abort.
    if (!$self->is_subrequest
        and $self->auto_send_headers
        and (!$retval or $retval==200)) {
        $r->send_http_header();
    }
}

sub redirect {
    my $self = shift;
    my $url = shift;
    my $status = shift || 302;

    $self->clear_buffer;

    $self->{cgi_request}->header_out( Location => $url );
    $self->{cgi_request}->header_out( Status => $status );

    $self->abort;
}

1;
