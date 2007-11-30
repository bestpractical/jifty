package Jifty::Plugin::Recorder;
use strict;
use warnings;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_accessors(qw/start path/);

use Time::HiRes 'time';
use YAML;

our $VERSION = 0.01;

=head2 init

init installs the trigger needed before each HTTP request. It also establishes
the baseline for all times.

=cut

sub init {
    my $self = shift;
    my %args = (
        path => 'log',
        @_,
    );

    return if $self->_pre_init;

    Jifty::Handler->add_trigger(
        before_request => sub { $self->before_request(@_) }
    );

    $self->start(time);
    $self->path($args{path});
}

=head2 before_request


=cut

sub before_request
{
    my $self    = shift;
    my $handler = shift;
    my $cgi     = shift;

    my $delta = time - $self->start;
    my $request = { cgi => $cgi, ENV => \%ENV, time => $delta };
    my $yaml = YAML::Dump($request);

    my $name = $self->path . '/requests-' . int($self->start) . '.log';
    open my $handle, '>>', $name or do {
        Jifty->log->error("Unable to open $name for appending: $!");
        return;
    };

    print $handle $yaml;

    close $handle;
}

=head1 NAME

Jifty::Plugin::Recorder

=head1 DESCRIPTION


=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Recorder: {}

=head1 SEE ALSO


=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


