package Jifty::Dispatcher;

# See Dispatcher.pod for documentaiton

use strict;
use warnings;
use Exporter;
use base 'Exporter';

our @EXPORT = qw<
    in on run when set del default

    show dispatch abort redirect

    GET POST PUT HEAD DELETE OPTIONS

    get next_action last_action

    $Dispatcher
>;

our $Dispatcher;

sub ret (@);
sub in ($$@)      { ret @_ } # partial match at beginning of path component
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
    @{$pkg.'::ACTIONS'} = ();

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
    $op    =~ s/.*:://;

    if ($Dispatcher) {
        # We are under an operation -- carry the action forward
        foreach my $action ([$op => splice(@_, 0, length($proto))], @_) {
            $Dispatcher->handle_action($action);
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
        push @{$pkg.'::ACTIONS'}, [$op => splice(@_, 0, length($proto))], @_;
    }
}

sub qualify ($@) {
    my $key = shift;
    my $op  = (caller(1))[3];
    $op =~ s/.*:://;
    return { $key => $op, '' => $_[0] };
}

sub actions {
    my $self = shift;
    my $pkg = ref($self) || $self;
    no strict 'refs';
    @{$pkg.'::ACTIONS'};
}

sub new {
    my $self = shift;
    return $self if ref($self);

    bless({
        path   => '',
        cwd    => '',
        action => undef,
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

sub handle_actions {
    my $self = shift;

    ACTION: foreach my $action (@_) {
        $self->handle_action($action);
    }
}

sub handle_action {
    my ($self, $action) = @_;
    my ($op, @args) = @$action;

    # Handle the case where $op is an array.
    local $@;
    eval {
        for my $sub_action (@$op, @args) {
            $self->handle_action($sub_action);
        }
    };
    return unless $@;

    local $self->{op} = $op;
    my $meth = "do_$op";
    $self->$meth(@args);
}

no warnings 'exiting';

sub next_action { next ACTION }
sub last_action { last HANDLER }

sub do_in {
    my ($self, $cond, $actions) = @_;
    if ( my $regex = $self->match($cond) ) {
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;

        # enter the matched directory
        local $self->{cwd} = substr($self->{path}, 0, $+[0]);
        $self->{cwd} =~ s{/$}{};

        $self->handle_actions(@$actions);
    }
}

sub do_when {
    my ($self, $code, $actions) = @_;
    if ( $code->() ) {
        $self->handle_actions(@$actions);
    }
}

sub do_on {
    my ($self, $cond, $actions) = @_;
    if ( my $regex = $self->match($cond) ) {
        # match again to establish $1 $2 etc in the dynamic scope
        $self->{path} =~ $regex;

        $self->handle_actions(@$actions);
    }
}

sub do_run {
    my ($self, $code) = @_;

    # establish void context and make a call
    $code->();

    # XXX maybe call with all the $1..$x as @_ too? or is it too gonzo?
    # $code->(map { substr($PATH, $-[$_], ($+[$_]-$-[$_])) } 1..$#-));

    return;
}

sub do_redirect {
    my ($self, $path) = @_;
    $self->{mason}->redirect($path);
    last_action;
}

sub do_abort {
    my $self = shift;
    $self->{mason}->abort(@_);
    last_action;
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

    $self->last_action;
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
        $self->handle_actions($self->actions, ['show']);
    }
    last_action;
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

    if ($Dispatcher->{action} eq 'on') {
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
