use strict;
use warnings;

=head1 NAME

 Jifty::Plugin::AuthLDAPLogin

=head1 DESCRIPTION

 MUST BE USED WITH LOGIN PLUGIN

=head1 CONFIG

 in etc/config.yml

  Plugins: 
    - Login: {}
    - AuthLDAPLogin: 
       LDAPserver: ldap.univ.fr
       LDAPbase: ou=people,dc=.....
       LDAPuid: uid
       LDAPemail: mailLocalAddress


=cut

package Jifty::Plugin::AuthLDAPLogin;
use base qw/Jifty::Plugin/;
use Net::LDAP;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

{
    my ($CurrentLDAPUserClass, $AuthLDAPUserClass, $LDAP, %params);

    sub init {
        my $self = shift;
        my %args = @_;
        my $appname = Jifty->config->framework('ApplicationName');
        $CurrentLDAPUserClass = $args{CurrentUserClass}
            || "${appname}::CurrentUser";
        $AuthLDAPUserClass = $args{AuthLDAPUserClass}
            || "${appname}::Model::LDAPUser";

	my ($conf);
    	foreach (@{Jifty->config->framework('Plugins')}) {
        	$conf = $_ if (defined $_->{'AuthLDAPLogin'});
    	}
    	$params{'Hostname'} = $conf->{'AuthLDAPLogin'}->{'LDAPserver'};
    	$params{'base'} = $conf->{'AuthLDAPLogin'}->{'LDAPbase'};
    	$params{'uid'} = $conf->{'AuthLDAPLogin'}->{'LDAPuid'};
    	$params{'email'} = $conf->{'AuthLDAPLogin'}->{'LDAPemail'};
    	$LDAP = Net::LDAP->new($params{Hostname},async=>1,onerror => 'undef',timeout => 3600, debug => 0);
    }

    sub CurrentLDAPUserClass {
        return $CurrentLDAPUserClass;
    }

    sub AuthLDAPUserClass {
        return $AuthLDAPUserClass;
    }

    sub LDAP {
	    return $LDAP;
    }

    sub base {
        return $params{'base'};
    }

    sub uid {
        return $params{'uid'};
    }

    sub email {
        return $params{'email'};
    }
}

1;
