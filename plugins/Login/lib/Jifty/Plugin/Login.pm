use strict;
use warnings;

package Jifty::Plugin::Login;
use base qw/Jifty::Plugin/;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.
{
    my ($CurrentUserClass, $LoginUserClass);

    sub init {
	my $self = shift;
	my %args = @_;
	my $appname = Jifty->config->framework('ApplicationClass');
	$CurrentUserClass = $args{CurrentUserClass}
	    || "${appname}::CurrentUser";
	$LoginUserClass = $args{LoginUserClass}
	    || "${appname}::Model::User";
    }

    sub CurrentUserClass {
	return $CurrentUserClass;
    }

    sub LoginUserClass {
	return $LoginUserClass;
    }
}

1;
