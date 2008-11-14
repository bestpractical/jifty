use strict;
use warnings;

package Jifty::View::Mason::Handler;

=head1 NAME

Jifty::View::Mason::Handler - Handler for Mason requests inside of Jifty

=head1 SUMMARY

Jifty controls all of the input and output from the Mason templating
engine; this means that we cannot use the Mason's standard
L<HTML::Mason::CGIHandler> interface to interact with it.

=cut

use HTML::Mason;
use HTML::Mason::Utils;
use Params::Validate qw(:all);
use HTML::Mason::Exceptions;
use HTML::Mason::FakeApache;
use Encode qw();

use Class::Container;
use base qw(Jifty::View Class::Container);

use HTML::Mason::MethodMaker
    ( read_write => [ qw( interp ) ] );

use vars qw($VERSION);

__PACKAGE__->valid_params
    (
     interp => { isa => 'HTML::Mason::Interp' },
    );

__PACKAGE__->contained_objects
    (
     interp => 'HTML::Mason::Interp',
    );


=head2 new PARAMHASH

Takes a number of key-value parameters; see L<HTML::Mason::Params>.
Defaults the C<out_method> to L</out_method>, and the C<request_class>
to L<HTML::Mason::Request::Jifty> (below).  Finally, adds C<h> and
C<u> escapes, which map to L</escape_uri> and L<escape_utf8>
respectively.

=cut

sub new {
    my $package = shift;

    my %p = @_ || $package->config;
    my $self = $package->SUPER::new( request_class => 'HTML::Mason::Request::Jifty',
                                     out_method => $package->can('out_method'),
                                     %p );
    $self->interp->compiler->add_allowed_globals('$r');
    $self->interp->set_escape( h => \&escape_utf8 );
    $self->interp->set_escape( u => \&escape_uri );

    return $self;
}


=head2 config

Returns our Mason config.  We use the component root specified in the
C<Web/TemplateRoot> framework configuration variable (or C<html> by
default).  Additionally, we set up a C<jifty> component root, as
specified by the C<Web/DefaultTemplateRoot> configuration.  All
interpolations are HTML-escaped by default, and we use the fatal error
mode.

=cut

sub config {
    my $self = shift;

    my %config = (
        static_source => 1,
        use_object_files => 1,
        preprocess => sub {
            # Force UTF-8 semantics on all our components by
            # prepending this block to all components as Mason
            # components defaults to parse the text as Latin-1
            ${$_[0]} =~ s!^!<\%INIT>use utf8;</\%INIT>\n!;
        },
        data_dir =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'DataDir'} ),
        allow_globals => [
            qw[ $JiftyWeb ],
            @{Jifty->config->framework('Web')->{'Globals'} || []},
        ],
        comp_root     => [ 
                          [application =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'TemplateRoot'} )],
                         ],
        %{ Jifty->config->framework('Web')->{'MasonConfig'} },
    );

    my $root_serial = 0;
    for my $plugin (Jifty->plugins) {
        my $comp_root = $plugin->template_root;
        unless  ( $comp_root and -d $comp_root) {
            next;
        }
        $plugin->log->debug( "Plugin @{[ref($plugin)]} mason component root added: (@{[$comp_root ||'']})");
        push @{ $config{comp_root} }, [ ref($plugin)."-". $root_serial++ => $comp_root ];
    }
    push @{$config{comp_root}}, [jifty => Jifty->config->framework('Web')->{'DefaultTemplateRoot'}];

    # In developer mode, we want halos, refreshing and all that other good stuff. 
    if (Jifty->config->framework('DevelMode') ) {
        push @{$config{'plugins'}}, 'Jifty::Mason::Halo';
        $config{static_source}    = 0;
        $config{use_object_files} = 0;
    }
    return %config;
}

=head2 escape_utf8 SCALARREF

Does a css-busting but minimalist escaping of whatever html you're passing in.

=cut

sub escape_utf8 {
    my $ref = shift;
    no warnings 'uninitialized';
    $$ref =~ s/&/&#38;/g;
    $$ref =~ s/</&lt;/g;
    $$ref =~ s/>/&gt;/g;
    $$ref =~ s/\(/&#40;/g;
    $$ref =~ s/\)/&#41;/g;
    $$ref =~ s/"/&#34;/g;
    $$ref =~ s/'/&#39;/g;
}

=head2 escape_uri SCALARREF

Escapes in-place URI component according to RFC2396. Takes a reference to
perl string.

*Note* that octets would be treated as latin1 encoded sequence and converted
to UTF-8 encoding and then escaped. So this sub always provide UTF-8 escaped
string. See also L<Encode> for more info about converting.

=cut

sub escape_uri {
    my $ref = shift;
    $$ref = Encode::encode_utf8($$ref);
    $$ref =~ s/([^a-zA-Z0-9_.!~*'()-])/uc sprintf("%%%02X", ord($1))/eg;
}


=head2 template_exists COMPONENT

A convenience method for $self->interp->comp_exists().  
(Jifty uses this method as part of its standard Templating system API).

=cut

sub template_exists {
	my $self = shift;
	return $self->interp->comp_exists(@_);
}


=head2 show COMPONENT

Takes a component path to render.  Deals with setting up a global
L<HTML::Mason::FakeApache> and Request object, and calling the
component.

=head2 handle_comp

A synonym for show

=cut

sub show {
    shift->handle_comp(@_);
}

sub handle_comp {
    my ($self, $comp, $args) = @_;

    Jifty->web->session->set_cookie;

    # Set up the global
    my $r = Jifty->handler->apache;
    $self->interp->set_global('$r', $r);

    # XXX FIXME This is a kludge to get use_mason_wrapper to work
    $self->interp->set_global('$jifty_internal_request', 0);
    $self->interp->set_global('$jifty_internal_request', 1) if defined $args;

    my %args = $args ? %$args : $self->request_args($r);

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
        Jifty->handler->send_http_header if $retval && grep { $retval eq $_ } ( 200, 301, 302 );

        return $retval;
    }

    return wantarray ? @result : defined wantarray ? $result[0] : undef;
}

=head2 request_args

The official source for request arguments is from the current
L<Jifty::Request> object.

=cut

sub request_args {
    return %{Jifty->web->request->arguments}, %{Jifty->web->request->template_arguments || {}};
}

###########################################################
package HTML::Mason::Request::Jifty;
# Subclass for HTML::Mason::Request object $m

=head1 HTML::Mason::Request::Jifty

Subclass of L<HTML::Mason::Request> which is customised for Jifty's use.

=cut

use HTML::Mason::Exceptions;
use HTML::Mason::Request;
use base qw(HTML::Mason::Request);

=head2 auto_send_headers

Doesn't send headers if this is a subrequest (according to the current
L<Jifty::Request>).

=cut

sub auto_send_headers {
    Jifty::View->auto_send_headers;
}

=head2 exec

Actually runs the component; in case no headers have been sent after
running the component, and we're supposed to send headers, sends them.

=cut

sub exec
{
    my $self = shift;
    my $r = Jifty->handler->apache;
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
    if ($self->auto_send_headers
        and not $r->http_header_sent
        and (!$retval or $retval==200)) {
        Jifty->handler->send_http_header;
    }
}

=head2 redirect

Calls L<Jifty::Web/redirect>.

=cut

sub redirect {
    my $self = shift;
    my $url = shift;

    Jifty->web->redirect($url);
}

1;
