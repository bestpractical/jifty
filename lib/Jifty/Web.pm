use warnings;
use strict;

package Jifty::Web;

=head1 NAME

Jifty::Web - Web framework for a Jifty application

=cut

use Jifty::Everything;
use CGI::Cookie;
use Apache::Session;
use base qw/Class::Accessor Jifty::Object/;

use UNIVERSAL::require;

__PACKAGE__->mk_accessors(qw(next_page request response session temporary_current_user action_limits));

=head1 METHODS

=head2 new

Creates a new C<Jifty::Web> object

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    return($self);
}

=head2 mason

Returns a L<HTML::Mason::Request> object

=cut

sub mason {
    return HTML::Mason::Request->instance;
}

=head2 setup_session

Sets up the current C<session> object (an L<Apache::Session> tied hash).
Also, restores saved Mason notes from the session if necessary.
Needs to be called before C<handle_request>.

=cut

# Create the Apache::Session object 
sub setup_session {
    my $self = shift;
    my $m    = $self->mason;
    return if $m && $m->is_subrequest;   # avoid reentrancy, as suggested by masonbook
    my %session;
    my %cookies       = CGI::Cookie->fetch();
    my $cookiename    = "Jifty_SID_" . $ENV{'SERVER_PORT'};
    my $session_class = 'Apache::Session::File';
    my $pm            = "$session_class.pm";
    $pm =~ s|::|/|g;
    require $pm;

    eval {
        tie %session, $session_class,
          ( $cookies{$cookiename} ? $cookies{$cookiename}->value() : undef ),
          {
            Directory     => '/tmp',
            LockDirectory => '/tmp'
          };
    };

    if ($@) {

        # If the session is invalid, create a new session.
        if ( $@ =~ /Object does not/i ) {
            tie %session, $session_class, undef,
              {
                Directory     => '/tmp',
                LockDirectory => '/tmp'
              };
            undef $cookies{$cookiename};
        }
        else {
            $self->log->fatal("Couldn't store your session:\n", $@);
            return;
        }
    }

    if ( !$cookies{$cookiename} ) {
        my $cookie = new CGI::Cookie(
            -name  => $cookiename,
            -value => $session{_session_id},
            -path  => '/',
        );
        # XXX TODO might need to change under mod_perl
         
        $m->cgi_request->headers_out->{'Set-Cookie'} = $cookie->as_string if ($m);

    }
    $self->session(\%session);


    $self->restore_state_from_session($self->request->notes_id) if ($self->request and $self->request->notes_id);
    return ();
}

=head2 save_session

If you're modifying something not at the top level of the session hash,
L<Apache::Session> won't notice and won't save your changes.  Thus, you should
call this method after you make any change to something nested inside the
session.

=cut

sub save_session {
    my $self = shift;
    $self->session->{'i'}++;
} 


=head2 session

Returns the current session's hash. In a regular user environment, it persists, but a request can
stop that by handing it a regular hash to use.

=cut

=head2 current_user [USER]

Getter/setter for the current user; this gets or sets the 'user' key
in the session.  These are L<Jifty::Record> objects.

If a temporary_current_user has been set, will return that instead.

=cut

sub current_user {
    my $self = shift;
    $self->session->{'user'} = shift if (@_);
    return $self->temporary_current_user || $self->session->{'user'};
}

=head2 temporary_current_user [USER]

Sets the current request's current_user to USER if set. 

This value will _not_ be persisted to the session at the end of the request.
To restore the original value, set temporary_current_user to undef.

=cut

=head2 handle_request



This method sets up a current session, prepares a Jifty::Request object
and loads page-specific actions.  Then it handles the meat of the
request.  That is, it C<run>s all of the L<Jifty::Action>s that have
been marked C<active> in the current L<Jifty::Request>.  To be run,
each action must also pass the L</is_allowed> check.  It then
L</redirect>s if a L</next_page> has been set.  See L<Jifty::Request>
for information about active actions.

=cut

sub handle_request {
    my $self = shift;
    
    $self->log->debug("Handling ".$ENV{'REQUEST_URI'});

    $self->request( Jifty::Request->new->from_mason_args );
    $self->response( Jifty::Response->new );
    $self->setup_session;
    $self->setup_page_actions;

    for my $request_action ($self->request->actions) {
        unless ($self->is_allowed($request_action->class)) {
            $self->log->warn("Attempt to call denied action '".$request_action->class."'");
            next;
        }

        next unless $request_action->active;

        my $action = $self->new_action_from_request($request_action);

        eval {
            $self->request->just_validating ? $action->validate_as_xml :
                                              $action->run ; 
            };

        $self->response->result($action->moniker => $action->result);

        # $@ is too magical -- accessing it twice can make it empty
        # the second time (?!)  Remove magic by stuffing it elsewhere.
        my $err = $@;
        if ($err) {
            $self->log->fatal($err);
            return;
        }
    }

    $self->redirect if $self->redirect_required;
} 


=head2 setup_page_actions

Probe the page the current user has requested to see if it has
any special actions it wants to run, if it wants to massage the existing actions,
etc.

=cut

sub setup_page_actions {
    my $self = shift;
    if ($self->mason->base_comp->method_exists('setup_actions')) {
        $self->mason->base_comp->call_method('setup_actions');
    }
}



=head2 request [VALUE]

Gets or sets the current L<Jifty::Request>.

=head2 response [VALUE]

Gets or sets the current L<Jifty::Response> object.

=head2 actions 

Gets the actions that have been created with this framework with C<new_action>
(whether automatically via a L<Jifty::Request>, or in Mason code), as L<Jifty::Action>
objects. (These are actually stored in the mason notes, so that they are magically saved over redirects.)

=cut

sub actions {
    my $self = shift;

    $self->mason->notes->{'actions'} ||= {};
    return sort {($a->order || 0) <=> ($b->order || 0)}
      values %{ $self->mason->notes->{'actions'} };
} 

sub _add_action {
    my $self = shift;
    my $action = shift;
   
    $self->mason->notes->{'actions'}{$action->moniker} = $action;
} 


=head2 allow_actions RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_allowed>.  See
L</restrict_actions> for the details of how limits are processed.

=cut

sub allow_actions {
    my $self = shift;
    $self->restrict_actions(allow => @_);
}

=head2 deny_actions RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_allowed>.  See
L</restrict_actions> for the details of how limits are processed.

=cut

sub deny_actions {
    my $self = shift;
    $self->restrict_actions(deny => @_);
}

=head2 restrict_actions POLARITY RESTRICTIONS

Method that L</allow_actions> and and L</deny_actions> call
internally; I<POLARITY> is either C<allow> or C<deny>.  Allow and deny
limits are evaluated in the order they're called.  The last limit that
applies will be the one which takes effect.  Regexes are matched
against the class; strings are fully qualified with the application's
I<ActionBasePath> (if they not already) and used as an exact match
against the class name.

If you call:

    Jifty->framework->allow_actions ( qr'.*' );
    Jifty->framework->deny_actions  ( qr'Foo' );
    Jifty->framework->allow_actions ( qr'FooBar' );
    Jifty->framework->deny_actions ( qr'FooBarDeleteTheWorld' );


calls to MyApp::Action::Baz will succeed.
calls to MyApp::Action::Foo will fail.
calls to MyApp::Action::FooBar will pass.
calls to MyApp::Action::TrueFoo will fail.
calls to MyApp::Action::TrueFooBar will pass.
calls to MyApp::Action::TrueFooBarDeleteTheWorld will fail.
calls to MyApp::Action::FooBarDeleteTheWorld will fail.

=cut

sub restrict_actions {
    my $self = shift;
    my $polarity = shift;
    my @restrictions = @_;

    die "Polarity must be 'allow' or 'deny'" unless $polarity eq "allow" or $polarity eq "deny";

    $self->action_limits([]) unless $self->action_limits;

    for my $restriction (@restrictions) {
        # Fully qualify it if it's a string and not already so
        my $base_path = Jifty->framework_config('ActionBasePath');
        $restriction = $base_path . "::" . $restriction
          unless ref $restriction or $restriction =~ /^\Q$base_path\E/;

        # Add to list of restrictions
        push @{ $self->action_limits }, { $polarity => 1, restriction => $restriction };
    }
}

=head2 is_allowed CLASS

Returns false if the I<CLASS> name (which is fully qualified with the
application's ActionBasePath if it is not already) is allowed to be
executed.  See L</restrict_actions> above for the rules that the class
name must pass.

=cut

sub is_allowed {
    my $self = shift;
    my $class = shift;

    my $base_path = Jifty->framework_config('ActionBasePath');
    $class = $base_path . "::" . $class
      unless $class =~ /^\Q$base_path\E/;


    # Assume that it passes
    my $allow = 1;

    $self->action_limits([]) unless $self->action_limits;

    for my $limit (@{ $self->action_limits }) {
        # For each limit
        if ((ref $limit->{restriction} and $class =~ $limit->{restriction})
           or ($class eq $limit->{restriction})) {
            # If the restriction passes, set the current allow/deny
            # bit according to if this was a positive or negative
            # limit
            $allow = $limit->{allow} ? 1 : 0;
        }
    }
    return $allow;
}

=head2 next_page [VALUE]

Gets or sets the next page for the framework to show.  This is
normally set during the C<take_action> method or a L<Jifty::Action>

=head2 redirect_required

Returns true if we need to redirect, now that we've processed all the
actions.  The current logic just looks to see if a different
L</next_page> has been set. We probably want to make it possible to
force a redirect, even if we're redirecting back to the current page

=cut

sub redirect_required {
    my $self = shift;

    if (   $self->next_page and (($self->next_page ne $self->mason->request_comp->path ) 
                                or $self->request->next_page_state_variables))
    {
        return (1);

    }
    else {
        return undef;
    }
}


=head2 redirect [URL]

Redirect to the next page. If you pass this method a parameter, it
redirects to that URL rather than B<next_page>.

It appends a C<J:N> parameter which is used to recreate the mason
notes structure after the redirect.

=cut

sub redirect {
    my $self = shift;
    my $page = shift || $self->next_page;


    my $uuid = $self->save_state_to_session();

    $page .= ( $page =~ /\?/ ? ';' : '?' )
        . join(
        ';',
       (map  { "J:V-" . $_->key . "=" . $_->value }
            $self->request->next_page_state_variables )
        ,
        "J:N=$uuid");

    $self->mason->redirect($page);
}

=head2 save_state_to_session

Saves the current L<Jifty::Response>, as well as the current Mason
notes into the user's session.

Returns the key for this state.

=cut

sub save_state_to_session {
    my $self = shift;
    my $uuid = shift;

    my $session = $self->session;
    my $key;
    do {
        $key = '';
        $key .= chr(int(rand(55))+65) for(1..6) ;
    } while ( exists $session->{'state'}{$key} );

    $self->session->{'state'}{$key} = {
        notes    => $self->mason->notes,
        response => $self->response,
    };

    $self->save_session;
    return ($key);
}

=head2 restore_state_from_session UUID

Restores the last L<Jifty::Response>, as well as the previous Mason
notes, from the user's session, under the key UUID.

=cut

sub restore_state_from_session {
    my $self = shift;
    my $uuid = shift;

    my $session = $self->session;
    return unless $session->{'state'} and $session->{'state'}{$uuid};
    my $state = delete $session->{'state'}{$uuid};
    $self->save_session; # $session won't notice the deep modification otherwise

    my $notes = $self->mason->notes;

    $self->response($state->{'response'}) if $state->{'response'};
    %$notes = %{ $state->{'notes'} } if $state->{'notes'};


} 

=head2 form

Returns the current L<Jifty::Web::Form> object, creating one if there
isn't one already.

=cut

sub form {
    my $self = shift;

    $self->{form} ||= Jifty::Web::Form->new;
    return $self->{form};
}

=head2 new_action class => CLASS, moniker => MONIKER, order => ORDER, arguments => PARAMHASH

Creates a new action (an instance of a subclass of L<Jifty::Action>)

C<CLASS> is appended to the C<ActionBasePath> found in the
configuration file, and an instance of that class is created, passing
the C<Jifty::Web> object, the C<MONIKER>, and any other arguments that
C<new_action> was supplied.

C<MONIKER> is a unique designator of an action on a page.  The moniker
is content-free and non-fattening, and may be auto-generated.  It is
used to tie together argumentss that relate to the same action.

C<ORDER> defines the order in which the action is run, with lower
numerical values running first.

C<ARGUMENTS> are passed to the L<Jifty::Action/new> method.  In
addition, if the current request (C<$self->request>) contains an
action with a matching moniker, any arguments thare are in that
requested action but not in the C<PARAMHASH> list are set.  This
implements "sticky fields".

=cut

sub new_action {
    my $self = shift;

    my %args = (
                class     => undef,
                moniker   => undef,
                arguments => {},
                @_
               );

    my $class   = delete $args{class};

    my $action_in_request = $self->request->action( $args{moniker} );

    # Fields explicitly passed to new_action take precedence over those passed
    # from the request; we read from the request to implement "sticky fields".
    # XXX TODO REFACTOR ME TO SANITY
    my %arguments = (( $action_in_request ? %{ $action_in_request->arguments || {} } : () ), %{$args{arguments}}); 

    # "Untaint" -- the implementation class is provided by the client!)
    # Allows anything that a normal package name allows
    unless ($class =~ /^([0-9a-zA-Z_:]+)$/) {
        $self->log->error("Bad action implementation class name: ", $class);
        return;
    } 
    $class = $1; # 'untaint'

    # Prepend the base path (probably "App::Action") unless it's there already
    my $base_path = Jifty->framework_config('ActionBasePath');
    $class = $base_path . "::" . $class
      unless $class =~ /^\Q$base_path\E::/ or $class =~ /^Jifty::Action::/;
    
    unless ($class->require) {
        # The implementation class is provided by the client, so this isn't a "shouldn't happen"
        $self->log->error("Error requiring $class: ", $UNIVERSAL::require::ERROR);
        return;
    }

    my $action;
    # XXX TODO bullet proof
    eval { $action = $class->new(%args, arguments => {%arguments}); };
    if ($@) {
        my $err = $@;
        $self->log->fatal($err);
        return;
    }

    $self->_add_action($action);

    return $action;
}

=head2 new_action_from_request REQUESTACTION

Given a L<Jifty::Request::Action>, creates a new action using C<new_action>.

=cut

sub new_action_from_request {
    my $self = shift;
    my $req_action = shift;
    $self->new_action(class => $req_action->class,
                      moniker => $req_action->moniker,
                      order => $req_action->order,
                      arguments => $req_action->arguments || {} );
}


=head2 render_messages

Outputs any messages that have been added, in a <div id="messages">
tag.  Messages are added by calling C<message> on a L<Jifty::Result>.

=cut

# XXX TODO factor out error and message rendering as separate

sub render_messages {
    my $self = shift;

    my %results = $self->response->results;

    return '' unless %results;

    for my $type  (qw(error message)) {
        next unless grep {$results{$_}->$type()} keys %results;

        my $plural = $type ."s";
        $self->mason->out(qq{<div id="$plural">});
        foreach my $moniker (keys %results) {
            if ($results{$moniker}->$type()) {
                $self->mason->out(qq/<div class="$type / . $moniker . '">');
                $self->mason->out($results{$moniker}->$type());
                $self->mason->out('</div>');
            }
        }
        $self->mason->out('</div>');
    }
    return '';
}


=head2 render_request_debug_info

Outputs the request arguments and any Mason notes in a <div
id="debug"> tag.

=cut

sub render_request_debug_info {
    my $self = shift;
    my $m = $self->mason;
    use YAML;
    $m->out('<div class="debug">');
    $m->out('<hr /><h1>Request args</h1><pre>');
    $m->out(YAML::Dump({$m->request_args}));
    $m->out('</pre>');
    $m->out('<hr /><h1>$m->notes</h1><pre>');
    $m->out(YAML::Dump($m->notes));
    $m->out('</pre></div>');

    return '';
}

=head2 query_string KEY => VALUE [, KEY => VALUE [, ...]]

Returns an URL-encoded query string piece representing the arguments
passed to it.

=cut

sub query_string {
  my $self = shift;
  my %args = @_;
  my @params;
  while ( (my $key, my $value) = each %args ){
        push @params, $key."=".$self->mason->interp->apply_escapes($value,'u');
  }
  return(join(';',@params));
}


=head2 query_string_from_current KEY => VALUE [, KEY => VALUE [, ...]]

Returns an URL-encoded query string piece representing the arguments
passed to it; any parameter to the current request that is not
specified here is also included with the current value.

Note that L<Jifty::Action> parameters are skipped to avoid actions
taking place that shouldn't.

=cut

sub query_string_from_current {
  my $self = shift;
  my %args = ($self->mason->request_args, @_);
  for (keys %args) {
    delete $args{$_} if /^Jifty::Action-/;
  }
  return $self->query_string( %args );
}


=head2 parameter_value KEY

Returns the value of top-level parameter with the provided C<KEY>.

=cut

sub parameter_value {
  my $self = shift;
  my $param_name = shift;
  return $self->mason->request_args->{$param_name};
}


=head2 expandable_element moniker => MONIKER [, label => LABEL] [, element => ELEMENT]

Renders an expandable element (ie, L<Jifty::View::Helper::Expandable>)
with the given label, moniker, and element.  The named parameters are
passed to the L<Jifty::View::Helper::Expandable> constructor;
C<MONIKER> is the only required value.

XXX TODO David Glasser, why is this helper in this class? it feels very strangely placed
DG says: API was made by obra in a SubEthaEdit session.  Feel free to suggest a better one
(I think I suggested just putting Jifty::View::Helper::Expandable->new(whatever)->render
in the code at the time and was told that that was bad.)

=cut

sub expandable_element {
    my $self = shift;
    my %args = (
        label => undef,
        moniker => undef,
        element => undef,
        @_
    ); 

    my $expander = Jifty::View::Helper::Expandable->new(%args)->render;
} 


=head2 navigation

Returns the L<Jifty::Web::Menu> for this web request; one is
automatically created if it hasn't been already.

=cut

sub navigation {
    my $self = shift;
    my $nav = $self->mason->notes("navigation");
    unless ($nav) {
        $nav = Jifty::Web::Menu->new();
        $self->mason->notes(navigation => $nav);
    }
    return $nav;
}


=head2 get_variable NAME

Gets a page specific variable from the request object.

Hm. should these methods be on the request and response objects?

=cut


sub get_variable {
    my $self = shift;
    my $name = shift;
    my $var = $self->request->state_variable($name);
    return undef unless ($var);
    return $var->value();

}

=head2 set_variable PARAMHAS

Takes a key-value pair for variables to serialize and hand off to the next page.

Behind the scenes, these variables get serialized into:

* Forms on the current page (using embedded parameters)
* Redirects, by adding the parameters to the URL

In the future, they might also get stuck into:
* URLs generated by our link generation method

=cut


sub set_variable {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{'state_variables'}->{$name} = $value;    

}

1;
