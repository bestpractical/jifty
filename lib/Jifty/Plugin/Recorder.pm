package Jifty::Plugin::Recorder;
use strict;
use warnings;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_accessors(qw/start path loghandle print_current_user/);

use Time::HiRes 'time';
use Jifty::Util;
use Storable 'nfreeze';

our $VERSION = 0.01;

=head2 init

init installs the trigger needed before each HTTP request. It also establishes
the baseline for all times and creates the log path.

=cut

sub init {
    my $self = shift;
    my %args = (
        path => 'log/requests',
        @_,
    );

    return if $self->_pre_init;

    $self->start(time);
    $self->path(Jifty::Util->absolute_path( $args{path} ));
    Jifty::Util->make_path($self->path);

    Jifty::Handler->add_trigger(
        before_request => sub { $self->before_request(@_) }
    );

    Jifty::Handler->add_trigger(
        before_cleanup => sub { $self->before_cleanup }
    );
}

=head2 before_request

Log as much of the request state as we can.

=cut

sub before_request
{
    my $self    = shift;
    my $handler = shift;
    my $cgi     = shift;

    $self->print_current_user(0);

    eval {
        my $delta = time - $self->start;
        my $request = { cgi => nfreeze($cgi), ENV => \%ENV, time => $delta };
        my $yaml = Jifty::YAML::Dump($request);

        print { $self->get_loghandle } $yaml;
        $self->print_current_user(1);
    };

    Jifty->log->error("Unable to append to request log: $@") if $@;
}

=head2 before_cleanup

Append the current user to the request log. This isn't done in one fell swoop
because if the server explodes during a request, we would lose the request's
data for logging.

This, strictly speaking, isn't necessary. But we don't always want to lug the
sessions table around, so this gets us most of the way there.

C<print_current_user> is checked to ensure that we don't append the current
user if the current request couldn't be logged for whatever reason (perhaps
a serialization error?).

=cut

sub before_cleanup {
    my $self = shift;

    if ($self->print_current_user) {
        eval {
            print { $self->get_loghandle } "current_user: " . (Jifty->web->current_user->id || 0) . "\n";
        };
    }
}

=head2 get_loghandle

Creates the loghandle. The created file is named C<PATH/BOOTTIME-PID.log>.

Returns C<undef> on error.

=cut

sub get_loghandle {
    my $self = shift;

    unless ($self->loghandle) {
        my $name = sprintf '%s/%d-%d.log',
                    $self->path,
                    $self->start,
                    $$;

        open my $loghandle, '>', $name or do {
            Jifty->log->error("Unable to open $name for writing: $!");
            return;
        };

        Jifty->log->info("Logging all HTTP requests to $name.");
        $self->loghandle($loghandle);
    }

    return $self->loghandle;
}

=head1 NAME

Jifty::Plugin::Recorder - record HTTP requests for playback

=head1 DESCRIPTION

This plugin will log all HTTP requests as YAML. The logfiles can be used by
C<jifty playback> (provided with this plugin) to replay the logged requests.
This can be handy for perfomance tuning, debugging, and testing.

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Recorder: {}

=head2 OPTIONS

=over 4

=item path

The path for creating request logs. Default: log/requests. This directory will
be created for you, if necessary.

=back

=head1 SEE ALSO

L<Jifty::Plugin::Recorder::Command::Playback>, L<HTTP::Server::Simple::Recorder>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


