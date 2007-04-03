use strict;
use warnings;

package Jifty::Plugin::Authentication::Password;
use base qw/Jifty::Plugin/;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

=head1 NAME

Jifty::Plugin::Authentication::Password

=head1 DESCRIPTION

When finished, this plugin will provide password authentication for 
your Jifty application. (It adds a "password" column to your "User" model class).

Right now, it's useless and should be ignored.


=cut

sub prereq_plugins {
    return ('User', 'LetMe');
}

1;
