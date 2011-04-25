package Jifty::Dispatcher;
use strict;
use warnings;
use Exporter;
use Jifty::YAML;
use base qw/Exporter Jifty::Object/;
use Carp::Clan; # croak

=head1 NAME

Jifty::Dispatcher - The Jifty Dispatcher

=head1 SYNOPSIS

In B<MyApp::Dispatcher>:

    package MyApp::Dispatcher;
    use Jifty::Dispatcher -base;

    under ['blog', 'wiki'] => [
        run {
            default model => "MyApp::Model::\u$1"
        },
        on PUT 'entries/*' => run {
            set entry_id => $1;
            show '/display/entry';
        },
        on '*/*' => run {
            my ($page, $op) = ($1, $2);
            my $item = get('model')->load($page) or next_rule;

            set item => $item;
            set page => $page;
            set op   => $op;

            show "/display/$op";
        },
        on '*' => run { dispatch "$1/view" },
        on ''  => show '/display/list',
    ];
    under qr{logs/(\d+)} => [
        when { $1 > 100 } => show '/error',
        set model => 'MyApp::Model::Log',
        run { dispatch "/wiki/LogPage-$1" },
    ];
    # ... more rules ...

=head1 DESCRIPTION

C<Jifty::Dispatcher> takes requests for pages, walks through a
dispatch table, possibly running code or transforming the request
before finally handing off control to the templating system to display
the page the user requested or whatever else the system has decided to
display instead.

Generally, this is B<not> the place to be performing model and user
specific access control checks or updating your database based on what
the user has sent in. You want to do that in your model
classes. (Well, I<we> want you to do that, but you're free to ignore
our advice).

The Dispatcher runs rules in several stages:

=over

=item before

B<before> rules are run before Jifty evaluates actions. They're the
perfect place to enable or disable L<Jifty::Action>s using
L<Jifty::API/allow> and L<Jifty::API/deny> or to completely disallow
user access to private I<component> templates such as the F<_elements>
directory in a default Jifty application.  They're also the right way
to enable L<Jifty::LetMe> actions.

You can entirely stop processing with the C<redirect>, C<tangent> and
C<abort> directives, though L</after> rules will still run.

=item on

L<on> rules are run after Jifty evaluates actions, so they have full
access to the results actions users have performed. They're the right
place to set up view-specific objects or load up values for your
templates.

Dispatcher directives are evaluated in order until we get to either a
C<show>, C<redirect>, C<tangent> or C<abort>.

=item after

L<after> rules let you clean up after rendering your page. Delete your
cache files, write your transaction logs, whatever.

At this point, it's too late to C<show>, C<redirect>, C<tangent> or C<abort>
page display.

=back

C<Jifty::Dispatcher> is intended to replace all the F<autohandler>,
F<dhandler> and C<index.html> boilerplate code commonly found in Mason
applications, but there's nothing stopping you from using those
features in your application when they're more convenient.

Each directive's code block runs in its own scope, but all share a
common C<$Dispatcher> object.

=cut

=head1 Plugins and rule ordering

By default, L<Jifty::Plugin> dispatcher rules are added in the order
they are specified in the application's configuration file; that is,
after all the plugin dispatchers have run in order, then the
application's dispatcher runs.  It is possible to specify rules which
should be reordered with respect to this rule, however.  This is done
by using a variant on the C<before> and C<after> syntax:

    before plugin NAME =>
        RULE(S);
    
    after plugin NAME =>
        RULE(S);

    after app,
        RULE(S)

C<NAME> may either be a string, which must match the plugin name
exactly, or a regular expression, which is matched against the plugin
name.  The rule will be placed at the first boundary that it matches --
that is, given a C<before plugin qr/^Jifty::Plugin::Auth::/> and both
a C<Jifty::Plugin::Auth::Basic> and a C<Jifty::Plugin::Auth::Complex>,
the rules will be placed before the first.

C<after app> inserts the following C<RULES> after the application's
dispatcher rules, and is identical to, but hopefully clearer than,
C<< after plugin Jifty => RULES >>.

C<RULES> may either be a single C<before>, C<on>, C<under>, or
C<after> rule to change the ordering of, or an array reference of
rules to reorder.

=cut

=head1 Data your dispatch routines has access to

=head2 request

The current L<Jifty::Request> object.

=head2 $Dispatcher

The current dispatcher object.

=head2 get $arg

Return the argument value. 

=head1 Things your dispatch routine might do

=head2 under $match => $rule

Match against the current requested path.  If matched, set the current
context to the directory and process the rule.

The C<$rule> may be an array reference of more rules, a code reference, a
method name of your dispatcher class, or a fully qualified subroutine name.

All wildcards in the C<$match> string becomes capturing regex patterns.  You
can also pass in an array reference of matches, or a regex pattern.

The C<$match> string may be qualified with a HTTP method name or protocol, such as

=over

=item GET

=item POST

=item PUT

=item OPTIONS

=item DELETE

=item HEAD

=item HTTPS

=item HTTP

=back

=head2 on $match => $rule

Like C<under>, except it has to match the whole path instead of just the prefix.
Does not set current directory context for its rules.

=head2 before $match => $rule

Just like C<on>, except it runs I<before> actions are evaluated.

=head2 after $match => $rule

Just like C<on>, except it runs I<after> the page is rendered.


=head2 when {...} => $rule

Like C<under>, except using an user-supplied test condition.  You can stick 
any Perl you want inside the {...}; it's just an anonymous subroutine.

=head2 run {...}

Run a block of code unconditionally; all rules are allowed inside a C<run>
block, as well as user code.  You can think of the {...} as an anonymous 
subroutine.

=head2 stream {...}

Run a block of code unconditionally, which should return a coderef
that is a PSGI streamy response.

=head2 set $arg => $val

Adds an argument to what we're passing to our template, overriding 
any value the user sent or we've already set.

=head2 default $arg => $val

Adds an argument to what we're passing to our template,
but only if it is not defined currently.

=head2 del $arg

Deletes an argument we were passing to our template.

=head2 show $component

Display the presentation component.  If not specified, use the
request path as the default page.

=head2 dispatch $path

Dispatch again using $path as the request path, preserving args.

=head2 next_rule

Break out from the current C<run> block and go on the next rule.

=head2 last_rule

Break out from the current C<run> block and stop running rules in this stage.

=head2 abort $code

Abort the request; this skips straight to the cleanup stage.

If C<$code> is specified, it's used as the HTTP status code.

=head2 redirect $uri

Redirect to another URI.

=head2 tangent $uri

Take a continuation here, and tangent to another URI.

=head2 plugin

=head2 app

See L</Plugins and rule ordering>, above.

=cut

our @EXPORT = qw<
    under run when set del default

    before on after

    show dispatch abort redirect tangent stream

    GET POST PUT HEAD DELETE OPTIONS

    HTTPS HTTP

    plugin app

    get next_rule last_rule

    already_run

    $Dispatcher
>;

our $Dispatcher;
our $Request;

sub request       { $Request }
sub _ret (@);
sub under ($$@)   { _ret @_ }    # partial match at beginning of path component
sub before ($$@)  { _ret @_ }    # exact match on the path component
sub on ($$@)      { _ret @_ }    # exact match on the path component
sub after ($$@)   { _ret @_ }    # exact match on the path component
sub when (&@)     { _ret @_ }    # exact match on the path component
sub run (&@)      { _ret @_ }    # execute a block of code
sub stream (&@)   { _ret @_ }    # web return a PSGI-streamy response
sub show (;$@)    { _ret @_ }    # render a page
sub dispatch ($@) { _ret @_ }    # run dispatch again with another URI
sub redirect ($@) { _ret @_ }    # web redirect
sub tangent ($@)  { _ret @_ }    # web tangent
sub abort (;$@)   { _ret @_ }    # abort request
sub default ($$@) { _ret @_ }    # set parameter if it's not yet set
sub set ($$@)     { _ret @_ }    # set parameter
sub del ($@)      { _ret @_ }    # remove parameter
sub get ($) {
    my $val = $Request->template_argument( $_[0] );
    return $val if defined $val;
    return $Request->argument( $_[0] );
}

sub _qualify ($@);
sub GET ($)     { _qualify method => @_ }
sub POST ($)    { _qualify method => @_ }
sub PUT ($)     { _qualify method => @_ }
sub HEAD ($)    { _qualify method => @_ }
sub DELETE ($)  { _qualify method => @_ }
sub OPTIONS ($) { _qualify method => @_ }

sub HTTPS ($)   { _qualify https  => @_ }
sub HTTP ($)    { _qualify http   => @_ }

sub plugin ($) { return { plugin => @_ } }
sub app ()     { return { plugin => 'Jifty' } }

our $CURRENT_STAGE;

=head2 import

Jifty::Dispatcher is an L<Exporter>, that is, part of its role is to
blast a bunch of symbols into another package. In this case, that
other package is the dispatcher for your application.

You never call import directly. Just:

    use Jifty::Dispatcher -base;

in C<MyApp::Dispatcher>

=cut

sub import {
    my $class = shift;
    my $pkg   = caller;
    my @args  = grep { !/^-[Bb]ase/ } @_;

    no strict 'refs';
    no warnings 'once';
    for (qw/RULES_RUN RULES_SETUP RULES_CLEANUP RULES_DEFERRED/) {
        @{ $pkg . '::' . $_ } = ();
    }
    if ( @args != @_ ) {

        # User said "-base", let's push ourselves into their @ISA.
        push @{ $pkg . '::ISA' }, $class;

        # Turn on strict and warnings for them too, a la Moose
        strict->import;
        warnings->import;
    }

    $class->export_to_level( 1, @args );
}

###################################################
# Magically figure out the arity based on caller info.
sub _ret (@) {
    my $pkg   = caller(1);
    my $sub   = ( caller(1) )[3];
    my $proto = prototype($sub);
    my $op    = $sub;

    $proto =~ tr/@;//d;
    if ( my $idx = rindex( $op, '::' ) ) {
        $op = substr( $op, $idx + 2 );
    }

    if ($Dispatcher) {

        # We are under an operation -- carry the rule forward
        foreach my $rule ( [ $op => splice( @_, 0, length($proto) ) ], @_ ) {
            $Dispatcher->_handle_rule($rule);
        }
    } elsif (wantarray) {
        ( [ $op => splice( @_, 0, length($proto) ) ], @_ );
    } elsif ( defined wantarray ) {
        [ [ $op => splice( @_, 0, length($proto) ) ], @_ ];
    } else {
        _push_rule($pkg, [ $op => splice( @_, 0, length($proto) ) ] );
    }
}

sub _push_rule($$) {
    my($pkg, $rule) = @_;
    my $op = $rule->[0];
    my $ruleset;
    if ( ($op eq "before" or $op eq "after") and ref $rule->[1] and ref $rule->[1] eq 'HASH' and $rule->[1]{plugin} ) {
        $ruleset = 'RULES_DEFERRED';
    } elsif ( $op eq 'before' ) {
        $ruleset = 'RULES_SETUP';
    } elsif ( $op eq 'after' ) {
        $ruleset = 'RULES_CLEANUP';
    } else {
        $ruleset = 'RULES_RUN';
    }
    no strict 'refs';
    # XXX TODO, need to spec stage here.
    push @{ $pkg . '::' . $ruleset }, $rule;
}

sub _qualify ($@) {
    my $key = shift;
    my $op  = ( caller(1) )[3];
    $op =~ s/.*:://;
    return { $key => $op, '' => $_[0] };
}

=head2 rules STAGE

Returns an array of all the rules for the stage STAGE.

Valid values for STAGE are

=over

=item SETUP

=item RUN

=item CLEANUP

=back

=cut

sub rules {
    my $self  = shift;
    my $stage = shift;
    my $pkg   = ref($self) || $self;
    no strict 'refs';
    no warnings 'once';
    @{ $pkg . '::RULES_' . $stage };
}

=head2 new

Creates a new Jifty::Dispatcher object. You probably don't ever want
to do this. (Jifty.pm does it for you)

=cut

sub new {
    my $self = shift;
    return $self if ref($self);

    bless(
        {   cwd  => '',
            path => '',
            rule => undef,
            @_,
        } => $self
    );
}

=head2 handle_request

Actually do what your dispatcher does. For now, the right thing
to do is to put the following two lines first:

    require MyApp::Dispatcher;
    MyApp::Dispatcher->handle_request;


=cut

sub handle_request {
    my $self = shift;

    local $Dispatcher = $self->new();

    # XXX TODO: refactor this out somehow?
    # We don't want the previous mason request hanging aroudn once we start dispatching
    no warnings 'once';
    local $HTML::Mason::Commands::m = undef;
    # Mason introduces a DIE handler that generates a mason exception
    # which in turn generates a backtrace. That's fine when you only
    # do it once per request. But it's really, really painful when you
    # do it often, as is the case with fragments
    local $SIG{__DIE__} = 'DEFAULT';
    local $Request = Jifty->web->request;

    my $handler = $Dispatcher->can("fragment_handler");
    if ($Request->is_subrequest and $handler) {
        $handler->();
        return undef;
    }
    eval {
         $Dispatcher->_do_dispatch( Jifty->web->request->path);
    };
    if ( my $err = $@ ) {
        $self->log->warn(ref($err) . " " ."'$err'") if ( $err !~ /^ABORT/ );
    }
    return $Dispatcher->{stream};
}

=head2 _handle_stage NAME, EXTRA_RULES

Handles the all rules in the stage named C<NAME>.  Additionally, any
other arguments passed after the stage C<NAME> are added to the end of
the rules for that stage.

This is the unit which calling L</last_rule> skips to the end of.

=cut

sub _handle_stage {
    my ($self, $stage, @rules) = @_;

    # Set the current stage so that rules can make smarter choices;
    local $CURRENT_STAGE = $stage;
    Jifty->handler->call_trigger("before_dispatcher_$stage");

    eval { $self->_handle_rules( [ $self->rules($stage), @rules ] ); };
    if ( my $err = $@ ) {
        $self->log->warn( ref($err) . " " . "'$err'" )
            if ( $err !~ /^(LAST RULE|ABORT)/ );
        Jifty->handler->call_trigger("after_dispatcher_$stage");
        return $err =~ /^ABORT/ ? 0 : 1;
    }
    Jifty->handler->call_trigger("after_dispatcher_$stage");
    return 1;
}

=head2 _handle_rules RULESET

When handed an arrayref or array of rules (RULESET), walks through the 
rules in order, executing as it goes.


=cut

sub _handle_rules ($) {
    my ( $self, $rules ) = @_;

    my @rules;
    {
        local $@;
        eval { @rules = @$rules };
        @rules = $rules if $@;
    }
RULE: foreach my $rule (@rules) {
        $self->_handle_rule($rule);
    }
}

=head2 _handle_rule RULE

When handed a single rule in the form of a coderef, C<_handle_rule>, 
calls C<_do_run> on that rule and returns the result. When handed a 
rule that turns out to be an array of subrules, recursively calls
itself and evaluates the subrules in order.

=cut

sub _handle_rule {
    my ( $self, $rule ) = @_;
    my ( $op,   @args );

    # Handle the case where $rule is an array reference.
    if (ref($rule) eq 'ARRAY') {
        ( $op, @args ) = @$rule;
    } else {
        ( $op, @args ) = ( run => $rule );
    }

    # Handle the case where $op is an array.
    my $sub_rules;
    if (ref($op) eq 'ARRAY' ) {
         $sub_rules = [ @$op, @args ];
    }

    if ($sub_rules) {
        for my $sub_rule (@$sub_rules) {
            $self->_handle_rule($sub_rule);
        }
    }

    # Now we know op is a scalar.
    local $self->{rule} = $op;
    my $meth = "_do_$op";
    $self->$meth(@args);

}

no warnings 'exiting';

sub next_rule { next RULE }
sub last_rule { die "LAST RULE" }

=head2 _do_under

This method is called by the dispatcher internally. You shouldn't need to.

=cut

sub _do_under {
    my ( $self, $cond, $rules ) = @_;
    if ( my $regex = $self->_match($cond) ) {

        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;

        # enter the matched directory
        local $self->{cwd} = substr( $self->{path}, 0, $+[0] );
        chop $self->{cwd} if substr( $self->{cwd}, -1 ) eq '/';

        $self->_handle_rules($rules);
    }
}

=head2 _do_when

This method is called by the dispatcher internally. You shouldn't need to.

=cut

sub _do_when {
    my ( $self, $code, $rules ) = @_;
    if ( $code->() ) {
        $self->_handle_rules($rules);
    }
}

=head2 _do_before

This method is called by the dispatcher internally. You shouldn't need to.

=cut

sub _do_before {
    my ( $self, $cond, $rules ) = @_;
    if ( my $regex = $self->_match($cond) ) {

        $self->log->debug("Matched 'before' rule $regex for ".$self->{'path'});
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;
        $self->_handle_rules($rules);
    }

}

=head2 _do_on

This method is called by the dispatcher internally. You shouldn't need to.

=cut

sub _do_on {
    my ( $self, $cond, $rules ) = @_;
    if ( my $regex = $self->_match($cond) ) {

        $self->log->debug("Matched 'on' rule $regex for ".$self->{'path'});
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;
        $self->_handle_rules($rules);
    }
}

=head2 _do_after

This method is called by the dispatcher internally. You shouldn't need to.

=cut

sub _do_after {
    my ( $self, $cond, $rules ) = @_;
    if ( my $regex = $self->_match($cond) ) {
        $self->log->debug("Matched 'after' rule $regex for ".$self->{'path'});
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;
        $self->_handle_rules($rules);
    }
}

=head2 already_run

Returns true if the code block has run once already in this request.
This can be useful for 'after' rules to ensure that they only run
once, even if there is a sub-dispatch which would cause it to run more
than once.  The idiom is:

    after '/some/path/*' => run {
        return if already_run;
        # ...
    };

=cut

sub already_run {
    my $id = $Dispatcher->{call_rule};
    return 1 if get "__seen_$id";
    set "__seen_$id" => 1;
    return 0;
}

sub _do_run {
    my ( $self, $code ) = @_;

    # Keep track of the coderef being run, so we can know about
    # already_run
    local $self->{call_rule} = $code;

    # establish void context and make a call
    ( $self->can($code) || $code )->();

    # XXX maybe call with all the $1..$x as @_ too? or is it too gonzo?
    # $code->(map { substr($PATH, $-[$_], ($+[$_]-$-[$_])) } 1..$#-));

    return;
}

=head2 _do_redirect PATH

This method is called by the dispatcher internally. You shouldn't need to.

Redirect the user to the URL provided in the mandatory PATH argument.

=cut

sub _do_redirect {
    my ( $self, $path ) = @_;
    $self->log->debug("Redirecting to $path");
    Jifty->web->redirect($path);
}

=head2 _do_tangent PATH

This method is called by the dispatcher internally. You shouldn't need to.

Take a tangent to the URL provided in the mandatory PATH argument.
(See L<Jifty::Manual::Continuation> for more about tangents.)

=cut

sub _do_tangent {
    my ( $self, $path ) = @_;
    $self->log->debug("Taking a tangent to $path");
    Jifty->web->tangent(url => $path);
}

=head2 _do_stream CODE

The method is called by the dispatcher internally. You shouldn't need to.

Take a coderef that returns a PSGI streamy response code.

=cut

sub _do_stream {
    my ( $self, $code ) = @_;
    $self->{stream} = $code->();
    $self->_abort;
}

=head2 _do_abort 

This method is called by the dispatcher internally. You shouldn't need to.

Don't display any page. just stop.

=cut

sub _do_abort {
    my $self = shift;
    $self->log->debug("Aborting processing");
    if (my $code = shift) {
        # This is the status code
        Jifty->web->response->status( $code );
        if ( $code == 403 && !Jifty->web->response->body) {
            Jifty->web->response->content_type('text/plain');
            Jifty->web->response->body('403 Forbidden');
        }
    }
    $self->_abort;
}

sub _abort { die "ABORT" }

=head2 _do_show [PATH]

This method is called by the dispatcher internally. You shouldn't need to.

Render a template. If the scalar argument "PATH" is given, render that component.
Otherwise, just render whatever we were going to anyway.

=cut


sub _do_show {
    my $self = shift;
    my $path;

    # Fix up the path
    $path = shift if (@_);
    $path = $self->{path} unless defined $path and length $path;

    unless ($CURRENT_STAGE eq 'RUN') {
        croak "You can't call a 'show' rule in a 'before' or 'after' block in the dispatcher.  Not showing path $path";
    }

    # If we've got a working directory (from an "under" rule) and we have
    # a relative path, prepend the working directory
    $path = "$self->{cwd}/$path" unless $path =~ m{^/};

    Jifty->web->render_template( $path );

    last_rule;
}

sub _do_set {
    my ( $self, $key, $value ) = @_;
    no warnings 'uninitialized';
    $self->log->debug("Setting argument $key to $value");
    $Request->template_argument($key, $value);
}

sub _do_del {
    my ( $self, $key ) = @_;
    $self->log->debug("Deleting argument $key");
    $Request->delete($key);
}

sub _do_default {
    my ( $self, $key, $value ) = @_;
    no warnings 'uninitialized';
    $self->log->debug("Setting argument default $key to $value");
    $Request->template_argument($key, $value)
        unless defined $Request->argument($key) or defined $Request->template_argument($key);
}

=head2 _do_dispatch [PATH]

First, this routine runs all the C<before> dispatcher rules, then it runs
Jifty->web->handle_request(), then it runs all the main C<on> rules,
evaluating each one in turn.  If it gets through all the rules without
running an C<abort>, C<redirect> or C<show> directive, it C<shows>
the template originally requested.

Once it's done with that, it runs all the cleanup rules defined with C<after>.

=cut

sub _do_dispatch {
    my $self = shift;

    # Requests should always start with a leading /
    $self->{path} = "/".shift;
    $self->{cwd}  = '';

    # Normalize the path.
    $self->{path} =~ s{/+}{/}g;

    $self->log->debug("Dispatching request to ".$self->{path});

    # Disable most actions on GET requests
    Jifty->api->deny_for_get() if $self->_match_method('GET');

    # Setup -- we we don't abort out of setup, then run the
    # actions and then the RUN stage.
    if ($self->_handle_stage('SETUP')) {
        # Run actions
        Jifty->web->handle_request unless Jifty->web->request->is_subrequest;

        # Run, and show the page
        $self->_handle_stage('RUN' => 'show');
    }

    # Close the handle down, so the client can go on their merry way
    unless (Jifty->web->request->is_subrequest) {
        Jifty->handler->call_trigger("before_flush");
        Jifty->handler->buffer->flush_output;
		# XXX: flush
		#close(STDOUT);
		#$Jifty::SERVER->close_client_sockets if $Jifty::SERVER;
        Jifty->handler->call_trigger("after_flush");
    }

    # Cleanup
    $self->_handle_stage('CLEANUP');

    # Out to the next dispatcher's cleanup; since try/catch using die
    # is slow, we only do this if we're not in the topmost dispatcher.
    $self->_abort if $self->{path} ne "/";
}

=head2 _match CONDITION

Returns the regular expression matched if the current request fits
the condition defined by CONDITION. 

C<CONDITION> can be a regular expression, a "simple string" with shell
wildcard characters (C<*>, C<?>, C<#>, C<[]>, C<{}>) to match against,
or an arrayref or hashref of those. It should even be nestable.

Arrayref conditions represents alternatives: the match succeeds as soon
as the first match is found.

Hashref conditions are conjunctions: each non-empty hash key triggers a
separate C<_match_$keyname> call on the dispatcher object. For example, a
C<method> key would call C<_match_method> with its value to be matched against.
After each subcondition is tried (in lexicographical order) and succeeded,
the value associated with the C<''> key is matched again as the condition.

=cut

sub _match {
    my ( $self, $cond ) = @_;

    # Handle the case where $cond is an array.
    if ( ref($cond) eq 'ARRAY' ) {
        local $@;
        my $rv = eval {
            for my $sub_cond (@$cond)
            {
                return ( $self->_match($sub_cond) or next );
            }
        };
        if ( my $err = $@ ) {
            warn "$self _match failed: $err";
        } else {
            return $rv;
        }
    }

    # Handle the case where $cond is a hash.
    elsif ( ref($cond) eq 'HASH' ) {
        local $@;
        my $rv = eval {
            for my $key ( sort grep {length} keys %$cond )
            {
                my $meth = "_match_$key";
                $self->$meth( $cond->{$key} ) or return;
            }

            # All precondition passed, get original condition literal
            return $self->_match( $cond->{''} ) if $cond->{''};

            # Or, if we don't have a literal, we win.
            return 1;
        };
        if ( my $err = $@ ) {
            warn "$self _match failed: $err";
        } else {
            return $rv;
        }
    }

    # Now we know $cond is a scalar, match against it.
    else {
        my $regex = $self->_compile_condition($cond) or return;
        $self->{path} =~ $regex or return;
        return $regex;
    }
}

=head2 _match_method METHOD

Takes an HTTP method. Returns true if the current request
came in with that method.

=cut

sub _match_method {
    my ( $self, $method ) = @_;
    #$self->log->debug("Matching method ".Jifty->web->request->method." against ".$method);
    $Request->method eq uc($method);
}

=head2 _match_https

Returns true if the current request is under SSL.

=cut

sub _match_https {
    my $self = shift;
    $self->log->debug("Matching request against HTTPS");
    return Jifty->web->request->secure;
}

=head2 _match_http

Returns true if the current request is not under SSL.

=cut

sub _match_http {
    my $self = shift;
    $self->log->debug("Matching request against HTTP");
    return !Jifty->web->request->secure;
}

sub _match_plugin {
    my ( $self, $plugin ) = @_;
    warn "Deferred check shouldn't happen";
    return 0;
}

=head2 _compile_condition CONDITION

Takes a condition defined as a simple string and return it as a regex
condition.

=cut


my %CONDITION_CACHE;

sub _compile_condition {
    my ( $self, $cond ) = @_;

    # Previously compiled (eg. a qr{} -- return it verbatim)
    return $cond if ref $cond;

    my $cachekey = join('-',
                        (($Dispatcher->{rule} eq 'on') ? 'on' : 'in'),
                        $self->{cwd},
                        $cond);
    unless ( $CONDITION_CACHE{$cachekey} ) {

        my $compiled = $cond;

        # Escape and normalize
        $compiled = quotemeta($compiled);
        $compiled =~ s{(?:\\\/)+}{/}g;
        $compiled =~ s{/$}{};

        my $has_capture = ( $compiled =~ / \\ [*?#] /x );
        if ( $has_capture or $compiled =~ / \\ [[{] /x ) {
            $compiled = $self->_compile_glob($compiled);
        }

        if ( $compiled =~ m{^/} ) {

            # '/foo' => qr{^/foo}
            $compiled = "\\A$compiled";
        } elsif ( length($compiled) ) {

            # 'foo' => qr{^$cwd/foo}
            $compiled = "(?<=\\A$self->{cwd}/)$compiled";
        } else {

            # empty path -- just match $cwd itself
            $compiled = "(?<=\\A$self->{cwd})";
        }

        if ( $Dispatcher->{rule} eq 'on' ) {

            # "on" anchors on complete match only
            $compiled .= '/?\\z';
        } else {

            # "in" anchors on prefix match in directory boundary
            $compiled .= '(?=/|\\z)';
        }

        # Make all metachars into capturing submatches
        if ( !$has_capture ) {
            $compiled = "($compiled)";
        }
        $CONDITION_CACHE{$cachekey} = qr{$compiled};
    }
    return $CONDITION_CACHE{$cachekey};
}

=head2 _compile_glob METAEXPRESSION

Private function.

Turns a metaexpression containing C<*>, C<?> and C<#> into a capturing regex pattern.

Also supports the non-capturing C<[]> and C<{}> notations.

The rules are:

=over 4

=item *

A C<*> between two C</> characters, or between a C</> and end of string,
should match one or more non-slash characters:

    /foo/*/bar
    /foo/*/
    /foo/*
    /*

=item *

All other C<*> can match zero or more non-slash characters: 

    /*bar
    /foo*bar
    *

=item *

Two stars (C<**>) can match zero or more characters, including slash:

    /**/bar
    /foo/**
    **

=item *

Consecutive C<?> marks are captured together:

    /foo???bar      # One capture for ???
    /foo??*         # Two captures, one for ?? and one for *

=item *

The C<#> character captures one or more digit characters.

=item *

Brackets such as C<[a-z]> denote character classes; they are not captured.

=item *

Braces such as C<{xxx,yyy}]> denote alternations; they are not captured.

=back

=cut

sub _compile_glob {
    my ( $self, $glob ) = @_;
    $glob =~ s{
        # Stars between two slashes, or between a slash and end-of-string,
        # should at match one or more non-slash characters.
        (?<= /)      # lookbehind for slash
        \\ \*        # star
        (?= / | \z)  # lookahead for slash or end-of-string
    }{([^/]+)}gx;
    $glob =~ s{
        # Two stars can match zero or more characters, including slash.
        \\ \* \\ \*
    }{(.*)}gx;
    $glob =~ s{
        # All other stars can match zero or more non-slash character.
        \\ \*
    }{([^/]*)}gx;
    $glob =~ s{
        # The number-sign character matches one or more digits.
        \\ \#
    }{(\\d+)}gx;
    $glob =~ s{
        # Consecutive question marks are captured as one unit;
        # we do this by capturing them and then repeat the result pattern
        # for that many times.  The divide-by-two takes care of the
        # extra backslashes.
        ( (?: \\ \? )+ )
    }{([^/]{${ \( length($1)/2 ) }})}gx;
    $glob =~ s{
        # Brackets denote character classes
        (
            \\ \[           # opening
            (?:             # one or more characters:
                \\ \\ \\ \] # ...escaped closing bracket
            |
                \\ [^\]]    # ...escaped (but not the closing bracket)
            |
                [^\\]       # ...normal
            )+
            \\ \]           # closing
        )
    }{$self->_unescape($1)}egx;
    $glob =~ s{
        # Braces denote alternations
        \\ \{ (         # opening (not part of expression)
            (?:             # zero or more characters:
                \\ \\ \\ \} # ...escaped closing brace
            |
                \\ [^\}]    # ...escaped (but not the closing brace)
            |
                [^\\]       # ...normal
            )+
        ) \\ \}         # closing (not part of expression)
    }{'(?:'.join('|', split(/\\,/, $1, -1)).')'}egx;
    $glob;
}

sub _unescape {
    my $self = shift;
    my $text = shift;
    $text =~ s{\\(.)}{$1}g;
    return $text;
}



=head2 import_plugins

Imports rules from L<Jifty/plugins> into the main dispatcher's space.

=cut

sub import_plugins {
    my $self = shift;

    # Find the deferred rules
    my @deferred;
    push @deferred, $_->dispatcher->rules('DEFERRED') for Jifty->plugins;
    push @deferred, $self->rules('DEFERRED');

    # XXX TODO: Examine @deferred and find rules that cannot fire
    # because they match no plugins; they should become un-deferred in
    # the appropriate group.  This is so 'before plugin qr/Auth/' runs
    # even if we have no auth plugin

    for my $stage (qw/SETUP RUN CLEANUP/) {
        my @groups;
        push @groups, {name => ref $_,  rules => [$_->dispatcher->rules($stage)]} for Jifty->plugins;
        push @groups, {name => 'Jifty', rules => [$self->rules($stage)]};

        my @left;
        my @rules;
        for (@groups) {
            my $name        = $_->{name};
            my @group_rules = @{$_->{rules}};

            # XXX TODO: 'after' rules should possibly be placed after
            # the *last* thing they could match
            push @rules, $self->_match_deferred(\@deferred, before => $name, $stage);
            push @rules, @group_rules;
            push @rules, $self->_match_deferred(\@deferred, after => $name, $stage);
        }

        no strict 'refs';
        @{ $self . "::RULES_$stage" } = @rules;
    }
    if (@deferred) {
        warn "Leftover unmatched deferred rules: ".Jifty::YAML::Dump(\@deferred);
    }
}

sub _match_deferred {
    my $self = shift;
    my ($deferred, $time, $name, $stage) = @_;
    my %stages = (SETUP => "before", RUN => "on", CLEANUP => "after");
    $stage = $stages{$stage};

    my @matches;
    for my $op (@{$deferred}) {
        # Only care if we're on the correct side of the correct plugin
        next unless $op->[0] eq $time;

        # Regex or string match, appropriately
        next unless (
            ref $op->[1]{plugin}
            ? ( $name =~ $op->[1]{plugin} )
            : ( $op->[1]{plugin} eq $name ) );

        # Find the list of subrules
        my @subrules = ref $op->[2] eq "ARRAY" ? @{$op->[2]} : ($op->[2]);

        # Only toplevel rules make sense (before, after, on)
        warn "Invalid subrule ".$_->[0] for grep {$_->[0] !~ /^(before|on|after)$/} @subrules;
        @subrules = grep {$_->[0] =~ /^(before|on|after)$/} @subrules;

        # Only match if the stage matches
        push @matches, grep {$_->[0] eq $stage} @subrules;
        @subrules = grep {$_->[0] ne $stage} @subrules;

        $op->[2] = [@subrules];
    }

    # Clean out any completely matched rules
    @$deferred = grep {@{$_->[2]}} @$deferred;

    return @matches;
}

1;
