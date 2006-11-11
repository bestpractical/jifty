use strict;
use warnings;

=head1 NAME

Jifty::Plugin::Login

=cut

package Jifty::Plugin::Login;
use base qw/Jifty::Plugin/;

=head1 SYNOPSIS

 in etc/config.yml
    Plugins:
      - Login: {}

 in your application Model/User.pm
   use strict;
   package YourApp::Model::User;
   use base qw/Jifty::Plugin::Login::Model::User/;
   1;

 in your application, you can use
  http://localhost:8888/login
                       /logout
                       /signup
                       /chgpasswd
                       /passwordreminder

=head1 DESCRIPTION

=cut

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
