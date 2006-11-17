use strict;
use warnings;

=head1 NAME

Jifty::Plugin::AuthLDAPLogin

=head1 DESCRIPTION

B<MUST BE USED WITH Login PLUGIN.>

Add ldap users in L<Jifty::Plugin::Login::Model::User>. 
Distinct id for ldap users is C<email> field with C<login@LDAP.user>

=head1 CONFIG

in etc/config.yml

  Plugins: 
    - Login: {}
    - AuthLDAPLogin: 
       LDAPhost: ldap.univ.fr           # ldap server
       LDAPbase: ou=people,dc=.....     # base ldap
       LDAPuid: uid                     # optional

=head1 SEE ALSO

L<Net::LDAP>

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

    	$params{'Hostname'} = $args{LDAPhost};
    	$params{'base'} = $args{LDAPbase};
    	$params{'uid'} = $args{LDAPuid} || "uid";
    	$LDAP = Net::LDAP->new($params{Hostname},async=>1,onerror => 'undef', debug => 0);
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

}

1;
