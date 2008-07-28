use strict;
use warnings;

package Jifty::Plugin::EmailErrors;
use base qw/Jifty::Plugin/;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

sub init {
    my $self = shift;
    my %args = @_;
    $Jifty::Plugin::EmailErrors::Notification::EmailError::TO = $args{to}     || 'nobody@localhost';
    $Jifty::Plugin::EmailErrors::Notification::EmailError::FROM = $args{from} || 'nobody@localhost';
    $Jifty::Plugin::EmailErrors::Notification::EmailError::SUBJECT = $args{subject} || 'Jifty error';
}

1;
