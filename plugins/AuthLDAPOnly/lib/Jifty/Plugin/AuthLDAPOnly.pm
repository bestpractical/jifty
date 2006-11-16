use strict;
use warnings;

=head1 NAME

 Jifty::Plugin::AuthLDAPOnly

=head1 DESCRIPTION

 MUST NOT BE USED WITH LOGIN PLUGIN

=head1 CONFIG

 in etc/config.yml
  Plugins: 
    - AuthLDAPOnly: 
       LDAPserver: ldap1.univ-metz.fr
       LDAPbase: ou=people, ou=...
       LDAPuid: uid
       LDAPemail: mailLocalAddress
                    

=cut

package Jifty::Plugin::AuthLDAPOnly;
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
        	$conf = $_ if (defined $_->{'AuthLDAPOnly'});
    	}
    	$params{'Hostname'} = $conf->{'AuthLDAPOnly'}->{'LDAPserver'};
    	$params{'base'} = $conf->{'AuthLDAPOnly'}->{'LDAPbase'};
    	$params{'uid'} = $conf->{'AuthLDAPOnly'}->{'LDAPuid'};
    	$params{'email'} = $conf->{'AuthLDAPOnly'}->{'LDAPemail'};
    	$LDAP = Net::LDAP->new($params{Hostname},async=>1,onerror => 'undef',timeout => 3600, debug => 0);
        #my $msg = $LDAP->bind($params{DN},password => $params{Passwd});
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
