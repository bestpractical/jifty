use strict;
use warnings;

=head1 NAME

Jifty::Plugin::Users;

=cut

package Jifty::Plugin::Users;
use base qw/Jifty::Plugin/;

=head1 SYNOPSIS

EXPERIMENTAL DON'T USE IT
EXPERIMENTAL DON'T USE IT
EXPERIMENTAL DON'T USE IT

 in etc/config.yml
     Plugins:
	   - Users: {}
       - Users-Identity-File:
			store: no

=cut

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

{
    my ($CurrentUserClass, $UserClass);

    sub init {
    my $self = shift;
    my %args = @_;
    my $appname = Jifty->config->framework('ApplicationClass');
    $UserClass = $args{UserClass}
        || Jifty->app_class('Model','Users');
    $CurrentUserClass = Jifty->app_class('CurrentUser')
    }

    sub CurrentUserClass {
    return $CurrentUserClass;
    }

    sub UserClass {
    return $UserClass;
    }
}


1;
