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
use Jifty::View::Mason::Request;

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
Defaults the C<out_method> to appending to L<Jifty::Handler/buffer>
and the C<request_class> to L<Jifty::View::Mason::Request> (below).
Finally, adds C<h> and C<u> escapes, which map to L</escape_uri> and
L<escape_utf8> respectively.

=cut

sub new {
    my $package = shift;

    $package->create_cache_directories;

    my %p = @_ || $package->config;
    my $self = $package->SUPER::new( request_class => 'Jifty::View::Mason::Request',
                                     out_method => sub {Carp::cluck("Mason output skipped Jifty's output stack!") if grep {defined and length} @_},
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
    my %seen; $seen{$_} = 1 for map Jifty->config->framework('Web')->{$_}, qw/TemplateRoot DefaultTemplateRoot/;
    for my $plugin (Jifty->plugins) {
        my $comp_root = $plugin->template_root;
        next unless ( defined $comp_root and -d $comp_root and not $seen{$comp_root}++);
        $plugin->log->debug( "Plugin @{[ref($plugin)]} mason component root added: (@{[$comp_root ||'']})");
        push @{ $config{comp_root} }, [ ref($plugin)."-". $root_serial++ => $comp_root ];
    }
    push @{$config{comp_root}}, [jifty => Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'DefaultTemplateRoot'})];

    # In developer mode, we want halos, refreshing and all that other good stuff. 
    if (Jifty->config->framework('DevelMode') ) {
        push @{$config{'plugins'}}, 'Jifty::View::Mason::Halo';
        $config{static_source}    = 0;
        $config{use_object_files} = 0;
    }

    # We require autoflush now.
    $config{autoflush} = 1;

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

Checks if the C<COMPONENT> exists, or if C<COMPONENT/index.html>
exists, and returns which one did.  If neither did, it seaches for
C<dhandler> components which could match, returning C<COMPONENT> if it
finds one.  Finally, if it finds no possible component matches,
returns undef.

Note that this algorithm does not actually decisively return if Mason
I<will> handle a given component; the I<dhandler>s could defer
handling, for instance.

=cut

sub template_exists {
    my $self = shift;
    my ($component) = @_;
    $component =~ s{^/*}{/};
    return $component if $self->interp->comp_exists($component);
    return "$component/index.html" if $self->interp->comp_exists("$component/index.html");

    my $dhandler = $self->interp->dhandler_name;
    $dhandler = "dhandler" unless defined $dhandler;
    return if defined $dhandler and not length $dhandler;
    return $component if $self->interp->find_comp_upwards($component, $dhandler);
    return undef;
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

sub _comp_setup {
    my ($self, $comp, $args) = @_;

    Jifty->web->session->set_cookie;

    # Set up the global
    my $r = Jifty->handler->apache;
    $self->interp->set_global('$r', $r);

    # XXX FIXME This is a kludge to get use_mason_wrapper to work
    $self->interp->set_global('$jifty_internal_request', 0);
    $self->interp->set_global('$jifty_internal_request', 1) if defined $args;

    return $args ? %$args : $self->request_args($r);
}

sub handle_comp {
    my $self = shift;
    my ($comp) = @_;

    my %args = $self->_comp_setup(@_);
    $self->interp->exec($comp, %args);
}

=head2 request_args

The official source for request arguments is from the current
L<Jifty::Request> object.

=cut

sub request_args {
    return %{Jifty->web->request->arguments}, %{Jifty->web->request->template_arguments || {}};
}


=head2 create_cache_directories

Attempts to create our app's mason cache directory.

=cut

sub create_cache_directories {
    for ( Jifty->config->framework('Web')->{'DataDir'} ) {
        Jifty::Util->make_path( Jifty::Util->absolute_path($_) );
    }
}

1;

