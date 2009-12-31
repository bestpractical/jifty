use warnings;
use strict;

package Jifty::Web;

=head1 NAME

Jifty::Web - Web framework for a Jifty application

=cut

use CGI::Cookie;
use XML::Writer;
use CSS::Squish;
use Digest::MD5 qw(md5_hex);
use Scalar::Util qw(blessed);
use Carp qw(carp);
use base qw/Class::Accessor::Fast Class::Data::Inheritable Jifty::Object/;

use vars qw/$SERIAL @JS_INCLUDES/;

__PACKAGE__->mk_accessors(
    qw(next_page force_redirect request response session temporary_current_user)
);

__PACKAGE__->mk_classdata($_)
    for qw(cached_css cached_css_digest cached_css_time
           css_files  javascript_libs   external_javascript_libs);

__PACKAGE__->css_files([qw( main.css )]);

__PACKAGE__->external_javascript_libs([]);

__PACKAGE__->javascript_libs([qw(
    jsan/JSAN.js
    jsan/Push.js
    setup_jsan.js
    jsan/Upgrade/Array/push.js
    jsan/DOM/Events.js
    json.js
    jquery-1.2.6.js
    iutil.js
    iautocompleter.js
    jifty_interface.js
    jquery_noconflict.js
    jquery.jgrowl.js
    facebox.js
    behaviour.js
    formatDate.js
    jifty.js
    jifty_utils.js
    jifty_subs.js
    jifty_smoothscroll.js
    calendar.js
    datetime.js
    dom-drag.js
    halo.js
    combobox.js
    key_bindings.js
    context_menu.js
    bps_util.js
    yui/yahoo.js
    yui/dom.js
    yui/event.js
    yui/calendar.js
    yui/element-beta.js
    yui/tabview.js
    yui/container.js
    yui/menu.js
    app.js
    app_behaviour.js
    css_browser_selector.js
    cssQuery-jquery.js
    jquery.timepickr.js
)]);

use Class::Trigger;

=head1 METHODS

=head3 new

Creates a new C<Jifty::Web> object

=cut

sub new {
    my $class = shift;
    my $self = bless {region_stack => []}, $class;
    $self->session(Jifty::Web::Session->new());
    $self->clear_state_variables;
    return ($self);
}

=head3 mason

Returns a L<HTML::Mason::Request> object

=cut

sub mason {
    use HTML::Mason::Request;
    return HTML::Mason::Request->instance;
}


=head3 out

Send a string to the browser. The default implementation uses Mason->out;

=cut

sub out {
    shift;
    Jifty->handler->buffer->append(@_);
}


=head3 url

Returns the root url of this Jifty application.  This is pulled from
the configuration file.  Takes an optional named path which will
form the path part of the resulting URL.

=cut

sub url {
    my $self = shift;
    my %args = (scheme => undef,
                path => undef,
                @_);

    my $uri;

    # Try to get a host out of the environment, useful in remote testing.
    # The code is a little hairy because there's no guarantee these
    # environment variables have all the information.
    if (my $http_host_env = $ENV{HTTP_HOST}) {
        # Explicit flag needed because URI->new("noscheme") is structurally
        # different from URI->new("http://smth"). Clunky, but works.
        my $dirty;
        if ($http_host_env !~ m{^http(s?)://}) {
            $dirty++;
            $http_host_env = (Jifty->web->is_ssl ? "https" : "http") ."://$http_host_env";
        }
        $uri = URI->new($http_host_env);
        if ($dirty && (my $req_uri_env = $ENV{REQUEST_URI})) {
            my $req_uri = URI->new($req_uri_env);
            $uri->scheme($req_uri->scheme) if $req_uri->can('scheme');
            $dirty = $uri->scheme;
        }
        # As a last resort, peek at the BaseURL configuration setting
        # for the scheme, which is an often-missing part.
        if ($dirty) {
            my $config_uri = URI->new(
                    Jifty->config->framework("Web")->{BaseURL});
            $uri->scheme($config_uri->scheme);
        }
    }

    if (!$uri) {
      my $url  = Jifty->config->framework("Web")->{BaseURL};
      my $port = Jifty->config->framework("Web")->{Port};
   
      $uri = URI->new($url);
      $uri->port($port);
    }

    # https is sticky
    $uri->scheme('https') if $uri->scheme eq 'http' && Jifty->web->is_ssl;

    if ( defined $args{'scheme'} ) {
        $uri->scheme( $args{'scheme'} );
    }

    if (defined $args{path}) {
      my $path = $args{path};
      # strip off leading '/' because ->canonical provides one
      $path =~ s{^/}{};
      $uri->path_query($path);
    }
    
    return $uri->canonical->as_string;
}

=head3 serial 

Returns a unique identifier, guaranteed to be unique within the
runtime of a particular process (ie, within the lifetime of Jifty.pm).
There's no sort of global uniqueness guarantee, but it should be good
enough for generating things like moniker names.

=cut

sub serial {
    my $class = shift;

    # We don't use a lexical for the serial number, because then it
    # would be reset on module refresh
    $SERIAL ||= 0;
    return join('', "S", ++$SERIAL, $$ );    # Start at 1.
}

=head2 SESSION MANAGEMENT

=head3 setup_session

Sets up the current C<session> object (a L<Jifty::Web::Session> tied
hash).  Aborts if the session is already loaded.

=cut

# Create the Jifty::Web::Session object
sub setup_session {
    my $self = shift;

    return if $self->session->loaded;
    $self->session->load();
}

=head3 session

Returns the current session's hash. In a regular user environment, it
persists, but a request can stop that by handing it a regular hash to
use.


=head2 CURRENT USER

=head3 current_user [USER]

Getter/setter for the current user; this gets or sets the 'user' key
in the session.  These are L<Jifty::Record> objects.

If a temporary_current_user has been set, will return that instead.

If the current application has no loaded current user, we get an empty
app-specific C<CurrentUser> object. (This
C<ApplicationClass>::CurrentUser class, a subclass of
L<Jifty::CurrentUser>, is autogenerated if it doesn't exist).

=cut

sub current_user {
    my $self = shift;
    if (@_) {
        my $currentuser_obj = shift;
        $self->session->set(
            'user_id' => $currentuser_obj ? $currentuser_obj->id : undef );
        $self->{current_user} = ( $currentuser_obj || undef );
    }

    my $object;

    if ( defined $self->temporary_current_user ) {
        return $self->temporary_current_user;
    } elsif ( defined $self->{current_user} ) {
        return $self->{current_user};
    } elsif ( my $id = $self->session->get('user_id') ) {
         $object = Jifty->app_class({require => 0}, "CurrentUser")->new( id => $id );
    } elsif ( Jifty->admin_mode ) {
         $object = Jifty->app_class({require => 0}, "CurrentUser")->superuser;
    } else {
         $object = Jifty->app_class({require => 0}, "CurrentUser")->new;
    }
    
    $self->{current_user} = $object;
    return $object;
}

=head3 temporary_current_user [USER]

Sets the current request's current_user to USER if set.

This value will _not_ be persisted to the session at the end of the
request.  To restore the original value, set temporary_current_user to
undef.

=cut

=head2 REQUEST

=head3 handle_request [REQUEST]

This method sets up a current session, and then processes the given
L<Jifty::Request> object.  If no request object is given, processes
the request object in L</request>.

Each action on the request is vetted in three ways -- first, it must
be marked as C<active> by the L<Jifty::Request> (this is the default).
Second, it must be in the set of allowed classes of actions (see
L<Jifty::API/is_allowed>).  Finally, the action must validate.  If it
passes all of these criteria, the action is fit to be run.

Before they are run, however, the request has a chance to be
interrupted and saved away into a continuation, to be resumed at some
later point.  This is handled by L<Jifty::Request/save_continuation>.

If the continuation isn't being saved, then C<handle_request> goes on
to run all of the actions.  If all of the actions are successful, it
looks to see if the request wished to call any continuations, possibly
jumping back and re-running a request that was interrupted in the
past.  This is handled by L<Jifty::Request/call_continuation>.

For more details about continuations, see L<Jifty::Continuation>.

=cut

sub handle_request {
    my $self = shift;
    die _("No request to handle") unless Jifty->web->request;

    my ( $valid_actions, $denied_actions )
        = $self->_validate_request_actions();

    # In the case where we have a continuation and want to redirect
    if ( $self->request->continuation_path && Jifty->web->request->argument('_webservice_redirect') ) {
        # for continuation - perform internal redirect under webservices
        $self->webservices_redirect($self->request->continuation_path);
        return;
    }

    $self->request->save_continuation;

    unless ( $self->request->just_validating ) {
        $self->_process_valid_actions($valid_actions);
        $self->_process_denied_actions($denied_actions);
    }

    # If there's a continuation call, don't do the rest of this
    return if $self->response->success and $self->request->call_continuation;

    $self->redirect if $self->redirect_required;
    $self->request->do_mapping;
}

sub _process_denied_actions {
    my $self           = shift;
    my $denied_actions = shift;

    for my $request_action (@$denied_actions) {
        my $action = $self->new_action_from_request($request_action);
        $action->deny( "Access Denied for " . ref($action) );
        $self->response->result( $action->moniker => $action->result );
    }
}

sub _validate_request_actions {
        my $self = shift;
        
    my @valid_actions;
    my @denied_actions;


    for my $request_action ( $self->request->actions ) {
        $self->log->debug( "Found action "
                . $request_action->class . " "
                . $request_action->moniker );
        next unless $request_action->active;
        next if $request_action->has_run;
        unless ( $self->request->just_validating ) {
            unless ( Jifty->api->is_allowed( $request_action->class ) ) {
                $self->log->warn( "Attempt to call denied action '"
                        . $request_action->class
                        . "'" );
                $self->log->warn( Jifty->api->explain($request_action->class ) );
                # Possible cross-site request forgery
                $self->log->error("Action " . $request_action->class . " has been denied because the request is a GET") if $self->request->request_method eq "GET";
                push @denied_actions, $request_action;
                next;
            }
        }

        # Make sure we can instantiate the action
        my $action = $self->new_action_from_request($request_action);
        next unless $action;
        $request_action->modified(0);

        # Try validating -- note that this is just the first pass; as
        # actions are run, they may fill in values which alter
        # validation of later actions
        $self->log->debug( "Validating action " . ref($action) . " " . $action->moniker );
        $self->response->result( $action->moniker => $action->result );
        $action->validate;

        push @valid_actions, $request_action;
    }
    
    return (\@valid_actions, \@denied_actions);

}

sub _process_valid_actions {
    my $self          = shift;
    my $valid_actions = shift;
    for my $request_action (@$valid_actions) {

        # Pull the action out of the request (again, since
        # mappings may have affected parameters).  This
        # returns the cached version unless the request has
        # been changed by argument mapping from previous
        # actions (Jifty::Request::Mapper)
        my $action = $self->new_action_from_request($request_action);
        next unless $action;
        if ( $request_action->modified ) {

            # If the request's action was changed, re-validate
            $action->result( Jifty::Result->new );
            $action->result->action_class( ref $action );
            $self->response->result( $action->moniker => $action->result );
            $self->log->debug( "Re-validating action "
                    . ref($action) . " "
                    . $action->moniker );
            next unless $action->validate;
        }

        $self->log->debug(
            "Running action " . ref($action) . " " . $action->moniker );
        eval { $action->run; };
        $request_action->has_run(1);

        if ( my $err = $@ ) {

            # Poor man's exception propagation; we need to get
            # "LAST RULE" and "ABORT" exceptions back up to the
            # dispatcher.  This is specifically for redirects from
            # actions
            die $err if ( $err =~ /^(LAST RULE|ABORT)/ );
            $self->log->fatal($err);
            $action->result->error(
                Jifty->config->framework("DevelMode")
                ? $err
                : _("There was an error completing the request.  Please try again later."
                )
            );
        }

        # Fill in the request with any results that that action
        # may have yielded.
        $self->request->do_mapping;
    }

}

=head3 request [VALUE]

Gets or sets the current L<Jifty::Request> object.

=head3 response [VALUE]

Gets or sets the current L<Jifty::Response> object.

=head3 form

Returns the current L<Jifty::Web::Form> object, creating one if there
isn't one already.

=cut

sub form {
    my $self = shift;

    $self->{form} ||= Jifty::Web::Form->new;
    return $self->{form};
}

=head3 new_action class => CLASS, moniker => MONIKER, order => ORDER, arguments => PARAMHASH

Creates a new action (an instance of a subclass of
L<Jifty::Action>). The named arguments passed to this method are
passed on to the C<new> method of the action named in C<CLASS>.
If you pass an odd number of arguments, then the first argument
is interpreted as C<class>.

=head3 Arguments

=over

=item class 

C<CLASS> is L<qualified|Jifty::API/qualify>, and an instance of that
class is created, passing the C<Jifty::Web> object, the C<MONIKER>,
and any other arguments that C<new_action> was supplied.

=item moniker

C<MONIKER> is a unique designator of an action on a page.  The moniker
is content-free and non-fattening, and may be auto-generated.  It is
used to tie together arguments that relate to the same action.

=item order

C<ORDER> defines the order in which the action is run, with lower
numerical values running first.

=item arguments

C<ARGUMENTS> are passed to the L<Jifty::Action/new> method.  In
addition, if the current request (C<< $self->request >>) contains an
action with a matching moniker, any arguments that are in that
requested action but not in the C<PARAMHASH> list are set.  This
implements "sticky fields".

=back

As a contrast to L<Jifty::Web::Form/add_action>, this does not add the
action to the current form -- instead, the first form field to be
rendered will automatically register the action in the current form
field at that time.

=cut

sub new_action {
    my $self = shift;

    # Handle new_action('CreateFoo', moniker => 'create_foo')
    unshift @_, 'class' if @_ % 2;

    my %args = (
        class     => undef,
        moniker   => undef,
        arguments => {},
        current_user => $self->current_user,
        @_
    );


    # "Untaint" -- the implementation class is provided by the client!)
    # Allows anything that a normal package name allows
    my $class = delete $args{class};
    unless ( $class =~ /^([0-9a-zA-Z_:]+)$/ ) {
        $self->log->error( "Bad action implementation class name: ", $class );
        return;
    }
    $class = $1;    # 'untaint'

    # Prepend the base path (probably "App::Action") unless it's there already
    $class = Jifty->api->qualify($class);

    # The implementation class is provided by the client, so this
    # isn't a "shouldn't happen"
    return unless Jifty::Util->require( $class );

    my $action;
    # XXX TODO bullet proof
    eval { $action = $class->new(%args) };
    if ($@) {
        my $err = $@;
        $self->log->fatal($err);
        return;
    }

    $self->{'actions'}{ $action->moniker } = $action;

    return $action;
}

=head3 new_action_from_request REQUESTACTION

Given a L<Jifty::Request::Action>, creates a new action using C<new_action>.

=cut

sub new_action_from_request {
    my $self       = shift;
    my $req_action = shift;
    return $self->{'actions'}{ $req_action->moniker } if 
      $self->{'actions'}{ $req_action->moniker } and not $req_action->modified;
    $self->new_action(
        class     => $req_action->class,
        moniker   => $req_action->moniker,
        order     => $req_action->order,
        arguments => $req_action->arguments || {}
    );
}

=head3 failed_actions

Returns an array of L<Jifty::Action> objects, one for each
L<Jifty::Request::Action> that is marked as failed in the current
response.

=cut

sub failed_actions {
    my $self = shift;
    my @actions;
    for my $req_action ($self->request->actions) {
        next unless $self->response->result($req_action->moniker);
        next unless $self->response->result($req_action->moniker)->failure;
        push @actions, $self->new_action_from_request($req_action);
    }
    return @actions;
}

=head3 succeeded_actions

As L</failed_actions>, but for actions that completed successfully;
less often used.

=cut

sub succeeded_actions {
    my $self = shift;
    my @actions;
    for my $req_action ($self->request->actions) {
        next unless $self->response->result($req_action->moniker);
        next unless $self->response->result($req_action->moniker)->success;
        push @actions, $self->new_action_from_request($req_action);
    }
    return @actions;
}

=head2 REDIRECTS AND CONTINUATIONS

=head3 next_page [VALUE]

Gets or sets the next page for the framework to show.  This is
normally set during the C<take_action> method or a L<Jifty::Action>

=head3 force_redirect [VALUE]

Gets or sets whether we should force a redirect to C<next_page>, even
if it's already the current page. You might set this, e.g. to force a
redirect after a POSTed action.

=head3 redirect_required

Returns true if we need to redirect, now that we've processed all the
actions. We need a redirect if either C<next_page> is different from
the current page, or C<force_redirect> has been set.

=cut

sub redirect_required {
    my $self = shift;

    return ( 1 ) if $self->force_redirect;

    if (!$self->request->is_subrequest
        and $self->next_page
        and ( ( $self->next_page ne $self->request->path )
              or $self->request->state_variables
              or $self->state_variables )
       )
    {
        return (1);

    } else {
        return undef;
    }
}

=head3 webservices_redirect [TO]

Handle redirection inside webservices call.  This is meant to be
hooked by plugin that knows what to do with it.

=cut

sub webservices_redirect {
    my ( $self, $to ) = @_;
    # XXX: move to singlepage plugin
    my ($spa) = Jifty->find_plugin('Jifty::Plugin::SinglePage') or return;

    return if $self->failed_actions;

    Jifty->web->request->remove_state_variable( 'region-'.$spa->region_name );
    Jifty->web->request->add_fragment(
        name      => $spa->region_name,
        path      => $to,
        arguments => {},
        wrapper   => 0
    );
}

=head3 redirect [TO]

Redirect to the next page. If you pass this method a parameter, it
redirects to that URL rather than B<next_page>.

It creates a continuation of where you want to be, and then calls it.
If you want to redirect to a page with parameters, pass in a
L<Jifty::Web::Form::Clickable> object.

=cut

sub redirect {
    my $self = shift;
    my $redir_to = shift || $self->next_page || $self->request->path;

    
    my $page;

    if ( ref $redir_to and $redir_to->isa("Jifty::Web::Form::Clickable")) {
        $page = $redir_to;
    } else {

        $page = Jifty::Web::Form::Clickable->new();
        #We set this after creation to ensure that plugins that massage clickables don't impact us
        $page->url($redir_to );
    }

    carp "Don't include GET parameters in the redirect URL -- use a Jifty::Web::Form::Clickable instead.  See L<Jifty::Web/redirect>" if $page->url =~ /\?/;

    my %overrides = ( @_ );
    $page->parameter($_ => $overrides{$_}) for keys %overrides;

    my @actions = Jifty->web->request->actions;

    # To submit a Jifty::Action::Redirect, we don't need to serialize a continuation,
    # unlike any other kind of actions.

    my $redirect_to_url = '' ;

    if (  (grep { not $_->action_class->isa('Jifty::Action::Redirect') }
                values %{ { $self->response->results } })
        or $self->request->state_variables
        or $self->state_variables
        or $self->request->continuation
        or grep { $_->active and not $_->class->isa('Jifty::Action::Redirect') } @actions )
    {
        my $request = Jifty::Request->new();
        $request->add_state_variable( key => $_->key, value => $_->value )
          for $self->request->state_variables;
        $request->add_state_variable( key => $_, value => $self->{state_variables}->{$_} )
          for keys %{ $self->{state_variables} };
        for (@actions) {
            my $new_action = $request->add_action(
                moniker   => $_->moniker,
                class     => $_->class,
                order     => $_->order,
                active    => $_->active && (not $_->has_run),
                has_run   => $_->has_run,
                arguments => $_->arguments,
            );

            # Clear out filehandles, which don't go thorugh continuations well
            for (keys %{$new_action->arguments || {}}) {
                $new_action->arguments->{$_} = ''
                    if ref($new_action->arguments->{$_}) eq "Fh"
                    || ref($new_action->arguments->{$_}) eq "Jifty::Web::FileUpload";
            }
        }
        my %parameters = ($page->parameters);
        $request->argument($_ => $parameters{$_}) for keys %parameters;

        # Apache, lighttpd, and HSS all do one pass of unescaping on
        # PATH_INFO, which is what $request->path is normally set to.
        # We should replicate that here.
        $request->path( URI::Escape::uri_unescape( $page->url ) );
        $request->request_method("GET"); # ..effectively.
        $request->continuation($self->request->continuation);
        my $cont = Jifty::Continuation->new(
            request  => $request,
            response => $self->response,
            parent   => $self->request->continuation,
        );
        $redirect_to_url = $page->url."?J:RETURN=" . $cont->id;
    } else {
        $redirect_to_url = $page->complete_url;
    }
    $self->_redirect($redirect_to_url);
}

sub _redirect {
    my $self = shift;
    my ($page) = @_;

    # It's an experimental feature to support redirect within a
    # region.
    if ($self->current_region) { 
        # If we're within a region stack, we don't really want to
        # redirect. We want to redispatch.  Also reset the things
        # applied on beofre.
        local $self->{navigation} = undef;
        local $self->{page_navigation} = undef;
        $self->replace_current_region($page);
        Jifty::Dispatcher::_abort();
        return;
    }

    if (my $redir = Jifty->web->request->argument('_webservice_redirect')) {
        push @$redir, $page;
        return;
    }
    # $page can't lead with // or it assumes it's a URI scheme.
    $page =~ s{^/+}{/};

    # This is designed to work under CGI or FastCGI; will need an
    # abstraction for mod_perl

    # Clear out the output, if any
    Jifty->handler->buffer->clear;

    my $apache = Jifty->handler->apache;

    $self->log->debug("Execing redirect to $page");
    # Headers..
    $apache->header_out( Location => $page );
    $apache->header_out( Status => 302 );

    # cookie has to be sent or returning from continuations breaks
    Jifty->web->session->set_cookie;

    Jifty->handler->send_http_header;

    # Mason abort, or dispatcher abort out of here
    $self->mason->abort if $self->mason;
    Jifty::Dispatcher::_abort();
}

=head3 caller

Returns the L<Jifty::Request> of our enclosing continuation, or an
empty L<Jifty::Request> if we are not in a continuation.

=cut

sub caller {
    my $self = shift;

    return Jifty::Request->new unless $self->request->continuation;
    return $self->request->continuation->request;
}

=head2 HTML GENERATION

=head3 tangent PARAMHASH

If called in non-void context, creates and renders a
L<Jifty::Web::Form::Clickable> with the given I<PARAMHASH>, forcing a
continuation save.

In void context, does a redirect to the URL that the
L<Jifty::Web::Form::Clickable> object generates.

Both of these versions preserve all state variables by default.

=cut

sub tangent {
    my $self = shift;

    if (@_ == 1  ) {
        $self->log->error("Jifty::Web->tangent takes a paramhash. Perhaps you passed '".$_[0]."' , rather than 'url => ".$_[0]."'");
        die; 
    }
    my $clickable = Jifty::Web::Form::Clickable->new(
        returns        => { },
        preserve_state => 1,
        @_
    );
    if ( defined wantarray ) {
        return $clickable->generate;
    } else {
        my $request = Jifty->web->request->clone;
        my %clickable = $clickable->get_parameters;
        $request->argument($_ => $clickable{$_}) for keys %clickable;
        local Jifty->web->{request} = $request;
        Jifty->web->request->save_continuation;
    }
}

=head3 goto PARAMHASH

Does an instant redirect to the url generated by the
L<Jifty::Web::Form::Clickable> object generated by the I<PARAMHASH>.

=cut

sub goto {
    my $self = shift;
    Jifty->web->redirect(
        Jifty::Web::Form::Clickable->new(@_));
}

=head3 link PARAMHASH

Generates and renders a L<Jifty::Web::Form::Clickable> using the given
I<PARAMHASH>.

=cut

sub link {
    my $self = shift;

    my $link = Jifty::Web::Form::Clickable->new(@_)->generate;

    return $link if defined wantarray;

    $link->render;
}

=head3 return PARAMHASH

If called in non-void context, creates and renders a
L<Jifty::Web::Form::Clickable> using the given I<PARAMHASH>,
additionally defaults to calling the current continuation.

Takes an additional argument, C<to>, which can specify a default path
to return to if there is no current continuation.

In void context, does a redirect to the URL that the
L<Jifty::Web::Form::Clickable> object generates.

=cut

sub return {
    my $self = shift;
    my %args = (to => undef,
                @_);
    my $continuation = Jifty->web->request->continuation;
    if (not $continuation and $args{to}) {
        $continuation = Jifty::Continuation->new(
            request => Jifty::Request->new(path => $args{to})
        );
    }
    delete $args{to};

    my $clickable = Jifty::Web::Form::Clickable->new(
        call => $continuation, %args
    );

    if ( defined wantarray ) {
        return $clickable->generate;
    }
    else {
        $self->redirect($clickable);
    }
}


=head2 template_exists PATH

Returns true if PATH is a valid template inside your template
root. This checks for both Template::Declare and HTML::Mason
Templates.  Specifically, returns a reference to the handler which can
process the template.

If PATH is a I<reference> to the path, it will update the path to
append C</index.html> if the path in question doesn't exist, but the
index does.

=cut

sub template_exists {
    my $self     = shift;
    my $template = shift;

    my $value = ref $template ? $$template : $template;

    foreach my $handler ( map {Jifty->handler->view($_)} Jifty->handler->view_handlers ) {
        if ( my $path = $handler->template_exists($value) ) {
            $$template = $path if ref $template;
            return $handler;
        }
    }
    return undef;
}



my %TEMPLATE_CACHE;

=head2 render_template PATH

Use our templating system to render a template.  Searches through
L<Jifty::Handler/view_handlers> to find the first handler which
provides the given template, and caches the handler for future
requests.

Catches errors, and redirects to C</errors/500>; also shows
C</errors/404> if the template cannot be found.

=cut

sub render_template {
    my $self     = shift;
    my $template = shift;
    my $handler;
    my $content;
        my $void_context = ( defined wantarray ? 0 :1);

    # Look for a possible handler, and cache it for future requests.
    # With DevelMode, always look it up.
    if ( not exists $TEMPLATE_CACHE{$template} or Jifty->config->framework('DevelMode')) {
        my $found = $template;
        $handler = $self->template_exists( \$found );
        # We don't cache failing URLs, so clients' can't cause us to
        # chew up memory by requesting 404's
        $TEMPLATE_CACHE{$template} = [ $found, $handler ] if $handler;
    }

    # Dig out the actual template (which could have a "/index.html" on
    # it, or what have you) and its handler.
    ($template, $handler) = @{$TEMPLATE_CACHE{$template} || [$template, undef] };

    # Handle 404's
    unless ($handler) {
        return $self->render_template("/errors/404") unless defined $template and $template eq "/errors/404";
        $self->log->warn("Can't find 404 page!");
        die "ABORT";
    }

    $self->log->debug("Showing path $template using @{[ref $handler]}");

    my $start_depth = Jifty->handler->buffer->depth;

    Jifty->handler->buffer->push( private => 1 ) unless $void_context;

    eval { $handler->show($template) };

    # Handle parse errors
    my $err = $@;

    $content = Jifty->handler->buffer->pop unless $void_context;


    if ( $err and not (eval { $err->isa('HTML::Mason::Exception::Abort') } or $err =~ /^ABORT/) ) {
        $self->log->fatal("View error: $err") if $err;
        if ($template eq '/errors/500') {
            $self->log->warn("Can't render internal_error: $err");
            # XXX Built-in static "oh noes" page?
                        die "ABORT";
        }

        # XXX: This may leave a half-written tag open
        $err->template_stack;
        Jifty->handler->buffer->pop while Jifty->handler->buffer->depth > $start_depth;

        # Save the request away, and redirect to an error page
        Jifty->web->response->error($err);
        my $c = Jifty::Continuation->new(
            request  => Jifty->web->request->top_request,
            response => Jifty->web->response,
            parent   => Jifty->web->request->continuation,
        );
        # Redirect with a continuation
        Jifty->web->_redirect( "/errors/500?J:C=" . $c->id );
    } elsif ($err) {
        Jifty->handler->buffer->pop while Jifty->handler->buffer->depth > $start_depth;
                die "ABORT";

    } else {
        return $content;
    }
}


=head3 render_messages [MONIKER]

Outputs any messages that have been added, in <div id="messages"> and
<div id="errors"> tags.  Messages are added by calling
L<Jifty::Result/message>.

If a moniker is specified, only messages for that moniker 
are rendered.


=cut

sub render_messages {
    my $self = shift;
    my $only_moniker = '';
    $only_moniker = shift if (@_);

    $self->render_error_messages($only_moniker);
    $self->render_success_messages($only_moniker);

    return '';
}

=head3 render_success_messages [MONIKER]

Render success messages for the given moniker, or all of them if no
moniker is given.

=cut

sub render_success_messages {
    my $self = shift;
    my $moniker = shift;

    $self->_render_messages('message', $moniker);

    return '';
}

=head3 render_error_messages [MONIKER]

Render error messages for the given moniker, or all of them if no
moniker is given.

=cut

sub render_error_messages {
    my $self = shift;
    my $moniker = shift;

    $self->_render_messages('error', $moniker);

    return '';
}

=head3 _render_messages TYPE [MONIKER]

Output any messages of the given TYPE (either 'error' or 'message') in
a <div id="TYPEs"> tag. If a moniker is given, only renders messages
for that action. Internal helper for L</render_success_messages> and
L</render_errors>.

=cut

sub _render_messages {
    my $self = shift;
    my $type = shift;
    my $only_moniker = shift || '';

    my %results = $self->response->results;

    %results = ($only_moniker => $results{$only_moniker}) if $only_moniker;

    return unless grep {$_->$type()} values %results;
    
    my $plural = $type . "s";
    $self->out(qq{<div class="jifty results messages" id="$plural">});
    
    foreach my $moniker ( sort keys %results ) {
        if ( $results{$moniker}->$type() ) {
            $self->out( qq{<div class="$type $moniker">}
                        . $results{$moniker}->$type()
                        . qq{</div>} );
        }
    }
    $self->out(qq{</div>});
}

=head3 query_string KEY => VALUE [, KEY => VALUE [, ...]]

Returns an URL-encoded query string piece representing the arguments
passed to it.

=cut

sub query_string {
    my $self = shift;
    my %args = @_;
    my @params;
    while ( ( my $key, my $value ) = each %args ) {
        push @params,
            $key . "=" . $self->escape_uri( $value );
    }
    return ( join( ';', @params ) );
}

=head3 escape STRING

HTML-escapes the given string and returns it

=cut

sub escape {
    no warnings 'uninitialized';
    my $self = shift;
    return join '', map {my $html = $_; Jifty::View::Mason::Handler::escape_utf8( \$html ); $html} @_;
}

=head3 escape_uri STRING

URI-escapes the given string and returns it

=cut

sub escape_uri {
    no warnings 'uninitialized';
    my $self = shift;
    return join '', map {my $uri = $_; Jifty::View::Mason::Handler::escape_uri( \$uri ); $uri} @_;
}

=head3 navigation

Returns the L<Jifty::Web::Menu> for this web request; one is
automatically created if it hasn't been already.

=cut

sub navigation {
    my $self = shift;
    if (!$self->{navigation}) {
        $self->{navigation} = Jifty::Web::Menu->new();
    }
    return $self->{navigation};
}

=head3 page_navigation

Returns the L<Jifty::Web::Menu> for this web request; one is
automatically created if it hasn't been already.  This is useful
for separating page-level navigation from app-level navigation.

=cut

sub page_navigation {
    my $self = shift;
    if (!$self->{page_navigation}) {
        $self->{page_navigation} = Jifty::Web::Menu->new();
    }
    return $self->{page_navigation};
}

=head3 include_css

Returns a C<< <link> >> tag for the compressed CSS

=cut

sub include_css {
    my $self = shift;

    # if there's no trigger, 0 is returned.  if aborted/handled, undef
    # is returned.
    defined $self->call_trigger( 'include_css', @_ ) or return '';

    $self->out( qq[<link rel="stylesheet" type="text/css" href="/static/css/$_" />\n] )
        for @{ Jifty->web->css_files };

    return '';
}

=head3 add_css FILE1, FILE2, ...

Pushes files onto C<< Jifty->web->css_files >>

=cut

sub add_css {
    my $self = shift;
    Jifty->web->css_files([
        @{ Jifty->web->css_files },
        @_
    ]);
}

=head3 include_javascript

Returns a C<< <script> >> tag for the compressed Javascript.

Your application specific javascript goes in
F<share/web/static/js/app.js>.  This will be automagically included if
it exists.

If you want to add javascript behaviour to your page using CSS
selectors then put your behaviour rules in
F<share/web/static/js/app_behaviour.js> which will also be
automagically included if it exists.  The C<behaviour.js> library is
included by Jifty.  For more information on C<behaviour.js> see
L<http://bennolan.com/behaviour/>.

However if you want to include other javascript libraries you need to
add them to the javascript_libs array of your application.  Do this in
the C<start> sub of your main application class.  For example if your
application is Foo then in L<lib/Foo.pm>

 sub start {
     Jifty->web->add_javascript(qw( jslib1.js jslib2.js ) );
 }

The L<add_javascript> method will append the files to javascript_libs.
If you need a different order, you'll have to massage javascript_libs
directly.

Jifty will look for javascript libraries under share/web/static/js/ by
default as well as any plugin static roots.

=cut

sub include_javascript {
    my $self  = shift;

    for my $url ( @{ __PACKAGE__->external_javascript_libs } ) {
        $self->out(
            qq[<script type="text/javascript" src="$url"></script>\n]
        );
    }

    # if there's no trigger, 0 is returned.  if aborted/handled, undef
    # is returned.
    if ( defined $self->call_trigger('include_javascript', @_) ) {
        for my $file ( @{ __PACKAGE__->javascript_libs } ) {
            $self->out(
                       qq[<script type="text/javascript" src="/static/js/$file"></script>\n]
                      );
        }
    }

    $self->call_trigger('after_include_javascript', @_);

    return '';
}

=head3 add_javascript FILE1, FILE2, ...

Pushes files onto C<< Jifty->web->javascript_libs >>

=cut

sub add_javascript {
    my $self = shift;
    Jifty->web->javascript_libs([ @{ Jifty->web->javascript_libs }, @_ ]);
}

=head3 remove_javascript FILE1, FILE2, ...

Removes the given files from C<< Jifty->web->javascript_libs >>.

This is intended for plugins or applications that provide another version of
the functionality given in our default JS libraries. For example, the CSSQuery
plugin will get rid of the cssQuery-jQuery.js back-compat script.

=cut

sub remove_javascript {
    my $self = shift;
    my %remove = map { $_ => 1 } @_;

    Jifty->web->javascript_libs([
        grep { !$remove{$_} } @{ Jifty->web->javascript_libs }
    ]);
}

=head3 add_external_javascript URL1, URL2, ...

Pushes urls onto C<< Jifty->web->external_javascript_libs >>

=cut

sub add_external_javascript {
    my $self = shift;
    Jifty->web->external_javascript_libs([
        @{ Jifty->web->external_javascript_libs }, @_ ]);
}

=head2 STATE VARIABLES

=head3 get_variable NAME

Gets a page specific variable from the request object.

=cut

sub get_variable {
    my $self = shift;
    my $name = shift;
    my $var  = $self->request->state_variable($name);
    return undef unless ($var);
    return $var->value();

}

=head3 set_variable NAME VALUE

Takes a key-value pair for variables to serialize and hand off to the next page.

Behind the scenes, these variables get serialized into every link or
form that is marked as 'state preserving'.  See
L<Jifty::Web::Form::Clickable>.

Passing C<undef> as a value will remove the variable

=cut

sub set_variable {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;

    if (!defined($value)) {
        delete $self->{state_variables}{$name};
    } else {
        $self->{state_variables}{$name} = $value;
    }

}

=head3 state_variables

Returns all of the state variables that have been set for the next
request, as a hash;

N.B. These are B<not> prefixed with C<J:V->, as they were in earlier
versions of Jifty

=cut

sub state_variables {
    my $self = shift;
    return %{ $self->{state_variables} };
}

=head3 clear_state_variables

Remove all the state variables to be serialized for the next request.

=cut

sub clear_state_variables {
    my $self = shift;

    $self->{state_variables} = {};
}

=head2 REGIONS

=head3 get_region [QUALIFIED NAME]

Given a fully C<QUALIFIED NAME> of a region, returns the
L<Jifty::Web::PageRegion> with that name, or undef if no such region
exists.

=cut

sub get_region {
    my $self = shift;
    my ($name) = @_;
    return $self->{'regions'}{$name};
}

=head3 region PARAMHASH

The provided PARAMHASH is used to create and render a
L<Jifty::Web::PageRegion>; the C<PARAMHASH> is passed directly to its
L<Jifty::Web::PageRegion/new> method, and then
L<Jifty::Web::PageRegion/render> is called.

=cut

sub region {
    my $self = shift;

    # Create a region
    my $region = Jifty::Web::PageRegion->new(@_) or return; 

    # Render it
    $region->render;
}


=head3 replace_current_region PATH

Replaces the current region with a new region and renders it Returns undef if there's no current region

=cut

sub replace_current_region {
    my $self = shift;
    my $path = shift;
    return undef unless (my $region = $self->current_region);
    $region->force_path($path);
    $region->render;
}


=head3 current_region

Returns the current L<Jifty::Web::PageRegion>, or undef if there is
none.

=cut

sub current_region {
    my $self = shift;
    return $self->{'region_stack'}
        ? $self->{'region_stack'}[-1]
        : undef;
}

=head3 qualified_region [REGION]

Returns the fully qualified name of the current
L<Jifty::Web::PageRegion>, or the empty string if there is none.  If
C<REGION> is supplied, gives the qualified name of C<REGION> were it
placed in the current region. You may also use a literal region name.

=cut

sub qualified_region {
    my $self = shift;
    join "-",
        map { ref($_) ? $_->name : $_ }
            @{ $self->{'region_stack'} || [] }, @_;
}

=head3 qualified_parent_region [REGION]

Returns the fully qualified name of the current
L<Jifty::Web::PageRegion>'s parent, or the empty string if there is none.  If
C<REGION> is supplied, gives the qualified name of C<REGION> were it
placed in the parent region. You may also use a literal region name.

=cut

sub qualified_parent_region {
    my $self = shift;
    my @region_stack = @{ $self->{'region_stack'} || [] };
    pop @region_stack;

    join "-",
        map { ref($_) ? $_->name : $_ }
            @region_stack, @_;
}

=head2 is_ssl

Indicates whether the current request was made using SSL.

=cut

sub is_ssl { $ENV{HTTPS} }

1;
