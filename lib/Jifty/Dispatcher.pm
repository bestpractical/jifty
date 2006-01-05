package Jifty::Dispatcher;
use strict;
use warnings;
use Exporter;
use base 'Exporter';

=head1 NAME

Jifty::Dispatcher - The Jifty Dispatcher

=head1 SYNOPSIS

In your F<autohandler>, change the C<< $m->call_next >> statement to:

    require MyApp::Dispatcher;
    MyApp::Dispatcher->handle_request;

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
        default model => 'MyApp::Model::Log',
        run { dispatch "/wiki/LogPage-$1" },
    ];
    # ... more rules ...

=head1 DESCRIPTION

C<Jifty::Dispatcher> takes requests for pages, walks through a
dispatch table, possibly running code or transforming the request
before finally handing off control to the templating system to display
the page the user requested or whatever else the system has decided to
display instead.

Generally, this is B<not> the place to be performing model and user specific
access control checks or updating your database based on what the user has sent
in. But it might be a good place to enable or disable specific
C<Jifty::Action>s using L<Jifty::Web/allow_actions> and
L<Jifty::Web/deny_actions> or to completely disallow user access to private
"component" templates such as the F<_elements> directory in a default Jifty
application.  It's also the right way to enable L<Jifty::LetMe> actions.

The Dispatcher runs I<before> any actions are evaluated, but I<after>
we've processed all the user's input.  It's intended to replace all the
F<autohandler>, F<dhandler> and C<index.html> boilerplate code commonly
found in Mason applications.

It doesn't matter whether the page the user's asked us to display
exists.  We're running the dispatcher either way. 

Dispatcher directives are evaluated in order until we get to either a
C<show>, C<redirect> or an C<abort>.

Each directive's code block runs in its own scope, but shares a common
C<$Dispatcher> object.

=cut

=head1 Data your dispatch routines has access to

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
C<GET>, C<POST> and C<PUT>.

=head2 on $match => $rule

Like C<under>, except it has to match the whole path instead of just the prefix.
Does not set current directory context for its rules.

=head2 when {...} => $rule

Like C<under>, except using an user-supplied test condition. 

=head2 run {...}

Run a block of code unconditionally; all rules are allowed inside a C<run>
block, as well as user code.  This is merely a syntactic sugar of C<sub>
or C<do> blocks.

=head2 set $arg => $val

Adds an argument to what we're passing to our template overriding 
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

=head2 abort $code

Abort the request.

=head2 redirect $uri

Redirect to another URI.

=cut

our @EXPORT = qw<
    under on run when set del default

    show dispatch abort redirect

    GET POST PUT HEAD DELETE OPTIONS

    get next_rule last_rule

    $Dispatcher
>;

our $Dispatcher;

sub ret (@);
sub under ($$@)      { ret @_ } # partial match at beginning of path component
sub on ($$@)      { ret @_ } # exact match on the path component
sub when (&@)     { ret @_ } # exact match on the path component
sub run (&@)      { ret @_ } # execute a block of code
sub show (;$@)    { ret @_ } # render a page
sub dispatch ($@) { ret @_ } # run dispatch again with another URI
sub redirect ($@) { ret @_ } # web redirect
sub abort (;$@)   { ret @_ } # abort request
sub default ($$@) { ret @_ } # set parameter if it's not yet set
sub set ($$@)     { ret @_ } # set parameter
sub del ($@)      { ret @_ } # remove parameter
sub get ($)       { $Dispatcher->{args}{$_[0]} }

sub qualify ($@);
sub GET ($)     { qualify method => @_ }
sub POST ($)    { qualify method => @_ }
sub PUT ($)     { qualify method => @_ }
sub HEAD ($)    { qualify method => @_ }
sub DELETE ($)  { qualify method => @_ }
sub OPTIONS ($) { qualify method => @_ }

sub import {
    my $class = shift;
    my $pkg   = caller;
    my @args  = grep {!/^-[Bb]ase/} @_;

    no strict 'refs';
    @{$pkg.'::RULES'} = ();

    if (@args != @_) {
        # User said "-base", let's push ourselves into their @ISA.
        push @{$pkg.'::ISA'}, $class;
    }

    $class->export_to_level(1, @_);
}


###################################################
# Magically figure out the arity based on caller info.
sub ret (@) {
    my $pkg   = caller(1);
    my $sub   = (caller(1))[3];
    my $proto = prototype($sub);
    my $op    = $sub;

    $proto =~ tr/@;//d;
    if (my $idx = rindex($op, '::')) {
        $op = substr($op, $idx + 2);
    }

    if ($Dispatcher) {
        # We are under an operation -- carry the rule forward
        foreach my $rule ([$op => splice(@_, 0, length($proto))], @_) {
            $Dispatcher->handle_rule($rule);
        }
    }
    elsif (wantarray) {
        ([$op => splice(@_, 0, length($proto))], @_);
    }
    elsif (defined wantarray) {
        [[$op => splice(@_, 0, length($proto))], @_];
    }
    else {
        no strict 'refs';
        push @{$pkg.'::RULES'}, [$op => splice(@_, 0, length($proto))], @_;
    }
}

sub qualify ($@) {
    my $key = shift;
    my $op  = (caller(1))[3];
    $op =~ s/.*:://;
    return { $key => $op, '' => $_[0] };
}

sub rules {
    my $self = shift;
    my $pkg = ref($self) || $self;
    no strict 'refs';
    @{$pkg.'::RULES'};
}

sub new {
    my $self = shift;
    return $self if ref($self);

    bless({
        cwd  => '',
        path => '',
        rule => undef,
        @_,
    } => $self);
}

sub handle_request {
    my $self = shift;

    my $m    = Jifty->web->mason;
    my $path = $m->request_comp->path;
    $path =~ s{/index\.html$}{};
    if ($path =~ s{/dhandler$}{}) {
        $path = join('/', $path, $m->dhandler_arg);
    }

    local $Dispatcher = $self->new(
        mason  => Jifty->web->mason,
        args   => { $m->request_args },
    );

    HANDLER: {
        $Dispatcher->do_dispatch($path);
    }
}

sub handle_rules ($) {
    my ($self, $rules) = @_;

    local $@;
    my @rules;
    eval { @rules = @$rules };
    @rules = $rules if $@;

    RULE: foreach my $rule (@rules) {
        $self->handle_rule($rule);
    }
}

sub handle_rule {
    my ($self, $rule) = @_;
    my ($op, @args);
    
    # Handle the case where $op is a code reference.
    {
        local $@;
        eval { ($op, @args) = @$rule };
        ($op, @args) = (run => $rule) if $@;
    }

    # Handle the case where $op is an array.
    local $@;
    eval {
        for my $sub_rule (@$op, @args) {
            $self->handle_rule($sub_rule);
        }
    };
    return unless $@;

    local $self->{rule} = $op;
    my $meth = "do_$op";
    $self->$meth(@args);
}

no warnings 'exiting';

sub next_rule { next RULE }
sub last_rule { last HANDLER }

sub do_under {
    my ($self, $cond, $rules) = @_;
    if ( my $regex = $self->match($cond) ) {
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;

        # enter the matched directory
        local $self->{cwd} = substr($self->{path}, 0, $+[0]);
        chop $self->{cwd} if substr($self->{cwd}, -1) eq '/';

        $self->handle_rules($rules);
    }
}

sub do_when {
    my ($self, $code, $rules) = @_;
    if ( $code->() ) {
        $self->handle_rules($rules);
    }
}

sub do_on {
    my ($self, $cond, $rules) = @_;
    if ( my $regex = $self->match($cond) ) {
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;

        $self->handle_rules($rules);
    }
}

sub do_run {
    my ($self, $code) = @_;

    # establish void context and make a call
    ($self->can($code) || $code)->($self);

    # XXX maybe call with all the $1..$x as @_ too? or is it too gonzo?
    # $code->(map { substr($PATH, $-[$_], ($+[$_]-$-[$_])) } 1..$#-));

    return;
}

sub do_redirect {
    my ($self, $path) = @_;
    Jifty->web->redirect($path);
    last_rule;
}

sub do_abort {
    my $self = shift;
    $self->{mason}->abort(@_);
    last_rule;
}

sub do_show {
    my ($self, $path) = @_;
    my $m = $self->{mason};

    if (!defined $path) {
        $m->call_next(%{$self->{args}});
    }
    else {
        $path = "$self->{cwd}/$path" unless $path =~ m{^/};
        $m->comp($path, %{$self->{args}});
    }

    $self->last_rule;
}

sub do_set {
    my ($self, $key, $value) = @_;

    $self->{args}{$key} = $value;
}

sub do_del {
    my ($self, $key) = @_;
    delete $self->{args}{$key};
}

sub do_default {
    my ($self, $key, $value) = @_;
    $self->{args}{$key} = $value
      unless defined $self->{args}{$key};
}

sub do_dispatch {
    my $self = shift;

    $self->{path} = shift;
    $self->{cwd}  = '';

    # Normalize the path.
    $self->{path} =~ s{/+}{/}g;
    $self->{path} =~ s{/$}{};

    HANDLER: {
        $self->handle_rules([$self->rules, 'show']);
    }
    last_rule;
}

sub match {
    my ($self, $cond) = @_;

    # Handle the case where $cond is an array.
    {
        local $@;
        my $rv = eval {
            for my $sub_cond (@$cond) {
                return($self->match($sub_cond) or next);
            }
        };
        return $rv unless $@;
    }

    # Handle the case where $cond is a hash.
    {
        local $@;
        my $rv =eval {
            for my $key (sort keys %$cond) {
                next if $key eq '';
                my $meth = "match_$key";
                $self->$meth($cond->{$key}) or return;
            }
            # All precondition passed, get original condition literal
            return $self->match($cond->{''});
        };
        return $rv unless $@;
    }

    # Now we know $cond is a scalar, match against it.
    my $regex = $self->compile_cond($cond) or return;
    $self->{path} =~ $regex or return;
    return $regex;
}

sub match_method {
    my ($self, $method) = @_;
    lc($self->{mason}->cgi_request->method) eq lc($method);
}

sub compile_cond {
    my ($self, $cond) = @_;

    # Previously compiled (eg. a qr{} -- return it verbatim)
    return $cond if ref $cond;

    # Escape and normalize
    $cond = quotemeta($cond);
    $cond =~ s{(?:\\\/)+}{/}g;
    $cond =~ s{/$}{};

    if ($cond =~ m{^/}) {
        # '/foo' => qr{^/foo}
        $cond = "\\A$cond"
    }
    elsif (length($cond)) {
        # 'foo' => qr{^$cwd/foo}
        $cond = "(?<=\\A$self->{cwd}/)$cond"
    }
    else {
        # empty path -- just match $cwd itself
        $cond = "(?<=\\A$self->{cwd})";
    }
    if ($Dispatcher->{rule} eq 'on') {
        # "on" anchors on complete match only
        $cond .= '\\z';
    }
    else {
        # "in" anchors on prefix match in directory boundary
        $cond .= '(?=/|\\z)';
    }

    # Make all metachars into capturing submatches
    unless ($cond =~ s{( (?: \\ [*?] )+ )}{'('. $self->compile_glob($1) .')'}egx) {
        $cond = "($cond)";
    }

    return qr{$cond};
}

sub compile_glob {
    my ($self, $glob) = @_;
    $glob =~ s{\\}{}g;
    $glob =~ s{\*}{[^/]+}g;
    $glob =~ s{\?}{[^/]}g;
    $glob;
}

1;
