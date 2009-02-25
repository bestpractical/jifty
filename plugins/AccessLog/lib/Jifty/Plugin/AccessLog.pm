package Jifty::Plugin::AccessLog;
use strict;
use warnings;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_accessors(qw/path format start/);

use Jifty::Util;
use CGI::Cookie;
use Time::HiRes qw();

our $VERSION = 0.01;

=head1 NAME

Jifty::Plugin::AccessLog - Concisely log Jifty requests

=head1 DESCRIPTION


=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - AccessLog: {}

=head2 OPTIONS

=over 4

=item path

The file to log to; defaults to F<log/access_log>.

=item format

The format string to use when logging.  This module attempts to be as
Apache-compatible as possible; it supports the following format
escapes:

=over

=item %%

The percent sign.

=item %a

Remote IP address.

=item %{Foobar}C

The contents of the cookie I<Foobar> in the request sent to the
server.

=item %D

The time taken to serve the request, in micoseconds.

=item %h

Remote IP address.

=item %{Foobar}n

The content of the I<Foobar> header line(s) in the request.

=item %l

The first 8 characters of the session ID, if any.

=item %m

The request method.

=item %{Foobar}n

The value of the template or request argument I<Foobar>, as sent by
the client, or set in the dispatcher.

=item %{Foobar}o

The value of the I<Foobar> header line(s) in the response.

=item %p

The canonical port of the server serving the request.  Alternate forms
include C<%{canonical}p>, C<%{local}p>, and C<%{remote}p>, which are
the respective connection ports.

=item %P

The process ID that serviced the request.

=item %s

The status code of the response.

=item %t

The time the request was recieved, formatted in Apache's default
format string (C<[%d/%b/%Y:%T %z]>).  C<%{I<format>}t> can be used to
provide a C<strftime>-style custom I<format>.

=item %T

The time taken to serve the request, in seconds.

=item %u

The value of L<Jifty::CurrentUser/username>, if any.

=item %U

The path requested.  In the event that the request was for one or more
regions, the list of regions will be given in square brackets.

=item %v

The canonical server name of the server.

=item %x

The list of active actions run in the request.  Failed actions will be
followed with an exclamation mark, un-run actions with a tilde.

=item %X

As C<%X>, but also includes all argument values to each action.

=back

=back

=head2 METHODS

=head2 init

Installs the trigger for each request.

=cut

sub init {
    my $self = shift;
    my %args = (
        path => 'log/access_log',
        format => '%h %l %u %t %m %U %s %T %x',
        @_,
    );

    return if $self->_pre_init;

    $self->path(Jifty::Util->absolute_path( $args{path} ));
    $self->format($args{format});
    Jifty::Handler->add_trigger(
        before_cleanup => sub { $self->before_cleanup }
    );
}

=head2 new_request

On each request, log when it starts.

=cut

sub new_request {
    my $self = shift;
    $self->start(Time::HiRes::time);
}

=head2 before_cleanup

Open, and append to, the logfile with the format specified.

=cut

sub before_cleanup {
    my $self = shift;
    my $cgi  = Jifty->handler->cgi;
    my $r    = Jifty->web->request;
    my $a    = Jifty->handler->apache;
    $a->header_out(Status => 200) unless defined $a->header_out("Status");

    my $actions = sub {
        my $long = shift;

        my $one_action = sub {
            my $a = shift;
            my $base = $a->class;
            my $result = Jifty->web->response->result($a->moniker);
            $base .= "~" if not $a->has_run or not $result;
            $base .= "!" if $result and not $result->success;
            return $base unless $long;
            return "($base={"
                . join( ",",
                map { "$_=" . $a->argument($_) } keys %{ $a->arguments } )
                . "})"
        };
        return sub {
            my @a = grep { $_->active } $r->actions;
            return "-" unless @a;
            ( $r->just_validating ? "V" : "" ) . "<" . join(
                ", ",    map {$one_action->($_)} @a) . ">";
        }
    };

    my %ESCAPES = (
        '%' => sub { '%' },
        a => sub { $cgi->remote_host },
        C => sub { my $c = { CGI::Cookie->fetch() }->{+shift}; $c ? $c->value : undef },
        D => sub { sprintf "%.3fms", (Time::HiRes::time - $self->start)*1000 },
        e => sub { $ENV{+shift} },
        h => sub { $cgi->remote_host },
        i => sub { $a->header_in(shift) },
        l => sub { substr( Jifty->web->session->id || '-', 0, 8 ) },
        m => sub { $r->request_method },
        n => sub { $r->template_argument($_[0]) || $r->argument($_[0]) },
        o => sub { $a->header_out(shift) },
        p => sub {
            return Jifty->config->framework("Web")->{Port} if $_[0] eq "canonical";
            return $ENV{SERVER_PORT} if $_[0] eq "local";
            return $ENV{REMOTE_PORT} if $_[0] eq "remote";
            return Jifty->config->framework("Web")->{Port};
        },
        P => sub { $$ },
        s => sub { $a->header_out("Status") },
        t => sub { DateTime->from_epoch($self->start)->strftime(shift || "[%d/%b/%Y:%T %z]") },
        T => sub { sprintf "%.3fs", (Time::HiRes::time - $self->start) },
        u => sub { Jifty->web->current_user->username },
        U => sub {
            my @f = $r->fragments;
            return $r->path unless @f;
            return '[' . join(", ", map {$_->path} @f ) . ']';
        },
        v => sub { URI->new(Jifty->config->framework("Web")->{BaseURL})->host },
        x => $actions->(0),
        X => $actions->(1),
    );

    my $replace = sub {
        my ($only_on, $string, $format) = @_;
        if (defined $only_on) {
            return "" unless grep {$a->header_out("Status") eq $_} split /,/, $only_on;
        }
        my $r;
        if (exists $ESCAPES{$format}) {
            $r = ref $ESCAPES{$format} ? eval {$ESCAPES{$format}->($string)} : $ESCAPES{$format};
        } else {
            $r = "%".$format;
        }
        return defined $r ? $r : "-";
    };


    my $s = $self->format;
    $s =~ s/%(\d+(?:,\d+)*)?(?:{(.*?)})?([a-zA-Z%])/$replace->($1,$2,$3)/ge;

    open my $access_log, '>>', $self->path or do {
        $self->log->error("Unable to open @{[$self->path]} for writing: $!");
        return;
    };
    $access_log->syswrite( "$s\n" );
    $access_log->close;
}

=head1 SEE ALSO

L<Jifty::Plugin::Recorder> for more verbose debugging information.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
