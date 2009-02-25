use strict;
use warnings;

package Jifty::Plugin::EmailErrors;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::EmailErrors - Emails all 500 pages to an arbitrary email address

=head1 SYNOPSIS

In your config.yml or equivilent:

  Plugins:
   - EmailErrors:
       to: address@example.com
       from: server@example.com
       subject: Server error

=head1 DESCRIPTION

All errors which result in the browser going to the '500 server error'
page will send an email with the stack trace that caused it.

=head1 METHODS

=head2 init

Sets up the global values for C<from>, C<to>, and C<subject>, based on
the plugin's provided configuration.

=cut

sub init {
    my $self = shift;
    my %args = @_;
    $Jifty::Plugin::EmailErrors::Notification::EmailError::TO = $args{to}     || 'nobody@localhost';
    $Jifty::Plugin::EmailErrors::Notification::EmailError::FROM = $args{from} || 'nobody@localhost';
    $Jifty::Plugin::EmailErrors::Notification::EmailError::SUBJECT = $args{subject} || 'Jifty error';
}

1;
