package Jifty::Dispatcher;
use strict;
use warnings;
use Exporter;
use base qw/Exporter Jifty::Object/;
           

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

You can entirely stop processing with the C<redirect> and C<abort>
directives.

=item on

L<on> rules are run after Jifty evaluates actions, so they have full
access to the results actions users have performed. They're the right
place to set up view-specific objects or load up values for your
templates.

Dispatcher directives are evaluated in order until we get to either a
C<show>, C<redirect> or an C<abort>.

=item after

L<after> rules let you clean up after rendering your page. Delete your
cache files, write your transaction logs, whatever.

At this point, it's too late to C<show>, C<redirect> or C<abort> page
display.

=back

C<Jifty::Dispatcher> is intended to replace all the F<autohandler>,
F<dhandler> and C<index.html> boilerplate code commonly found in Mason
applications, but there's nothing stopping you from using those
features in your application when they're more convenient.

Each directive's code block runs in its own scope, but all share a
common C<$Dispatcher> object.

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

The C<$match> string may be qualified with a HTTP method name, such as

=over

=item GET

=item POST

=item PUT

=item OPTIONS

=item DELETE

=item HEAD

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
default page in call_next.

=head2 dispatch $path

Dispatch again using $path as the request path, preserving args.

=head2 next_rule

Break out from the current C<run> block and go on the next rule.

=head2 last_rule

Break out from the current C<run> block and stop running rules in this stage.

=head2 abort $code

Abort the request.

=head2 redirect $uri

Redirect to another URI.


=head2 next_show

INTERNAL MAGIC YOU SHOULD NOT USE THAT ALEX SHOULD RENAME ;)

=cut

our @EXPORT = qw<
    under run when set del default

    before on after

    show dispatch abort redirect

    GET POST PUT HEAD DELETE OPTIONS

    get next_rule last_rule

    already_run

    $Dispatcher
>;

our $Dispatcher;

sub request       { Jifty->web->request }
sub _ret (@);
sub under ($$@)   { _ret @_ }    # partial match at beginning of path component
sub before ($$@)  { _ret @_ }    # exact match on the path component
sub on ($$@)      { _ret @_ }    # exact match on the path component
sub after ($$@)   { _ret @_ }    # exact match on the path component
sub when (&@)     { _ret @_ }    # exact match on the path component
sub run (&@)      { _ret @_ }    # execute a block of code
sub show (;$@)    { _ret @_ }    # render a page
sub dispatch ($@) { _ret @_ }    # run dispatch again with another URI
sub redirect ($@) { _ret @_ }    # web redirect
sub abort (;$@)   { _ret @_ }    # abort request
sub default ($$@) { _ret @_ }    # set parameter if it's not yet set
sub set ($$@)     { _ret @_ }    # set parameter
sub del ($@)      { _ret @_ }    # remove parameter
sub get ($) { request->argument( $_[0] ) }

sub _qualify ($@);
sub GET ($)     { _qualify method => @_ }
sub POST ($)    { _qualify method => @_ }
sub PUT ($)     { _qualify method => @_ }
sub HEAD ($)    { _qualify method => @_ }
sub DELETE ($)  { _qualify method => @_ }
sub OPTIONS ($) { _qualify method => @_ }

=head2 import

Jifty::Dispatcher is an L<Exporter>, that is, part of its role is to
blast a bunch of symbols into another package. In this case, that other
package is the dispatcher for your application.

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
    for (qw(RULES_RUN RULES_SETUP RULES_CLEANUP)) {
        @{ $pkg . '::' . $_ } = ();
    }
    if ( @args != @_ ) {

        # User said "-base", let's push ourselves into their @ISA.
        push @{ $pkg . '::ISA' }, $class;
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
    if ( $op eq 'before' ) {
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
    local $HTML::Mason::Commands::m = undef;
    # Mason introduces a DIE handler that generates a mason exception
    # which in turn generates a backtrace. That's fine when you only
    # do it once per request. But it's really, really painful when you do it
    # often, as is the case with fragments
    local $SIG{__DIE__} = 'DEFAULT';

    eval {
        $Dispatcher->_do_dispatch( Jifty->web->request->path);
    };
    if ( my $err = $@ ) {
        $self->log->warn(ref($err) . " " ."'$err'") if ( $err !~ /^LAST RULE/);
    }
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
sub last_rule { 
    
    # Mason introduces a DIE handler that generates a mason exception
    # which in turn generates a backtrace. That's fine when you only
    # do it once per request. But it's really, really painful when you do it
    # often, as is the case with fragments
   
      local $SIG{__DIE__} = 'IGNORE';

    die "LAST RULE"; 
}
sub next_show { last HANDLE_WEB }

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

Redirect the user to the URL provded in the mandatory PATH argument.

=cut

sub _do_redirect {
    my ( $self, $path ) = @_;
    $self->log->debug("Redirecting to $path");
    Jifty->web->redirect($path);
    last_rule;
}

=head2 _do_abort 

This method is called by the dispatcher internally. You shouldn't need to.

Don't display any page. just stop.

=cut

sub _do_abort {
    my $self = shift;
    $self->log->debug("Aborting processing");
    last_rule;
}

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
    $path ||= $self->{path};
    $self->log->debug("Showing path $path");

    # If we've got a working directory (from an "under" rule) and we have
    # a relative path, prepend the working directory
    $path = "$self->{cwd}/$path" unless $path =~ m{^/};

    # When we're requesting a directory, go looking for the index.html
    if ( $path =~ m{/$} and $self->template_exists( $path . "/index.html" ) )
    {

        $path .= "/index.html";
    }

    # Redirect to directory (and then index) if they requested
    # the directory itself

    # XXX TODO, we should search all component roots

    if ($path !~ m{/$}
        and -d Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'TemplateRoot'} . $path))
    {
        $self->_do_show( $path . "/" );
    }

    # Set the request path
    request->path($path);
    $self->render_template(request->path);


    last_rule;
}

sub _do_set {
    my ( $self, $key, $value ) = @_;
    $self->log->debug("Setting argument $key to $value");
    request->argument($key, $value);
}

sub _do_del {
    my ( $self, $key ) = @_;
    $self->log->debug("Deleting argument $key");
    request->delete($key);
}

sub _do_default {
    my ( $self, $key, $value ) = @_;
    $self->log->debug("Setting argument default $key to $value");
    request->argument($key, $value)
        unless defined request->argument($key);
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

    $self->{path} = shift;
    $self->{cwd}  = '';

    # Normalize the path.
    $self->{path} =~ s{/+}{/}g;

    $self->log->debug("Dispatching request to ".$self->{path});

    eval {
        $self->_handle_rules( [ $self->rules('SETUP') ] );
        HANDLE_WEB: { Jifty->web->handle_request(); }
        $self->_handle_rules( [ $self->rules('RUN'), 'show' ] );
    };
    if ( my $err = $@ ) {
        $self->log->warn(ref($err) . " " ."'$err'") if ( $err !~ /^LAST RULE/);
    }

    eval {
        $self->_handle_rules( [ $self->rules('CLEANUP') ] );
    };
    if ( my $err = $@ ) {
        $self->log->warn(ref($err) . " " ."'$err'") if ( $err !~ /^LAST RULE/);
    }

    last_rule;
}

=head2 _match CONDITION

Returns the regular expression matched if the current request fits
the condition defined by CONDITION. 

C<CONDITION> can be a regular expression, a "simple string" with shell
wildcard characters (C<*> and C<?>) to match against, or an arrayref or hashref
of those. It should even be nestable.

Arrayref conditions represents alternatives: the match succeeds as soon
as the first match is found.

Hashref conditions are conjunctions: each non-empty hash key triggers a
separate C<_match_$keyname> call on the dispatcher object. For example, a
C<method> key would call C<_match_method> with its value to be matched against.
After each subcondition is tried (in lexographical order) and succeeded,
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
            for my $key ( sort keys %$cond )
            {
                next if $key eq '';
                my $meth = "_match_$key";
                $self->$meth( $cond->{$key} ) or return;
            }

            # All precondition passed, get original condition literal
            return $self->_match( $cond->{''} );
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
    $self->log->debug("Matching URL ".$self->{cgi}->method." against ".$method);
    lc( $self->{cgi}->method ) eq lc($method);
}

=head2 _compile_condition CONDITION

Takes a condition defined as a simple string ad return it as a regex
condition.

=cut

sub _compile_condition {
    my ( $self, $cond ) = @_;

    # Previously compiled (eg. a qr{} -- return it verbatim)
    return $cond if ref $cond;

    # Escape and normalize
    $cond = quotemeta($cond);
    $cond =~ s{(?:\\\/)+}{/}g;
    $cond =~ s{/$}{};

    my $has_capture = ( $cond =~ / \\ [*?] /x);
    if ($has_capture) {
        $cond = $self->_compile_glob($cond);
    }

    if ( $cond =~ m{^/} ) {

        # '/foo' => qr{^/foo}
        $cond = "\\A$cond";
    } elsif ( length($cond) ) {

        # 'foo' => qr{^$cwd/foo}
        $cond = "(?<=\\A$self->{cwd}/)$cond";
    } else {

        # empty path -- just match $cwd itself
        $cond = "(?<=\\A$self->{cwd})";
    }

    if ( $Dispatcher->{rule} eq 'on' ) {

        # "on" anchors on complete match only
        $cond .= '/?\\z';
    } else {

        # "in" anchors on prefix match in directory boundary
        $cond .= '(?=/|\\z)';
    }

    # Make all metachars into capturing submatches
    if (!$has_capture) {
        $cond = "($cond)";
    }

    return qr{$cond};
}

=head2 _compile_glob METAEXPRESSION

Private function.

Turns a metaexpression containing * and ? into a capturing perl regex pattern.

The rules are:

=over 4

=item *

A C<*> between two C</> characthers, or between a C</> and end of string,
should at match one or more non-slash characters:

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

Consecutive C<?> marks are captured together:

    /foo???bar      # One capture for ???
    /foo??*         # Two captures, one for ?? and one for *

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
        # All other stars can match zero or more non-slash character.
        \\ \*
    }{([^/]*)}gx;
    $glob =~ s{
        # Consecutive question marks are captured as one unit;
        # we do this by capturing them and then repeat the result pattern
        # for that many times.  The divide-by-two takes care of the
        # extra backslashes.
        ( (?: \\ \? )+ )
    }{([^/]{${ \( length($1)/2 ) }})}gx;
    $glob;
}

=head2 template_exists PATH

Returns true if PATH is a valid template inside your template root.

=cut

sub template_exists {
    my $self = shift;
    my $template = shift;

      return  Jifty->handler->mason->interp->comp_exists( $template);

}


=head2 render_template PATH

Use our templating system to render a template. If there's an error, do the right thing.


=cut

sub render_template {
    my $self = shift;
    my $template = shift;

    $self->log->debug( "Handling template " . $template );
    eval { Jifty->handler->mason->handle_comp( $template ); };
    my $err = $@;

    # Handle parse errors
    if ( $err and not eval { $err->isa('HTML::Mason::Exception::Abort') } ) {

        # Save the request away, and redirect to an error page
        Jifty->web->response->error($err);
        my $c = Jifty::Continuation->new(
            request  => Jifty->web->request,
            response => Jifty->web->response,
            parent   => Jifty->web->request->continuation,
        );

        warn "$err";

        # Redirect with a continuation
        Jifty->web->_redirect(
            "/__jifty/error/mason_internal_error?J:C=" . $c->id );
    }
    elsif ($err) {
        die $err;
    }

}


=head2 import_plugins

Imports rules from L<Jifty/plugins> into the main dispatcher's space.

=cut

sub import_plugins {
    my $self = shift;
    for my $stage (qw/SETUP RUN CLEANUP/) {
        my @rules;
        push @rules, $_->dispatcher->rules($stage) for Jifty->plugins;
        push @rules, $self->rules($stage);

        no strict 'refs';
        @{ $self . "::RULES_$stage" } = @rules;
    }
}

1;
