use strict;
use warnings;

=head1 NAME

Jifty::Plugin::AuthLDAPOnly

=head1 DESCRIPTION

B<MUST NOT BE USED WITH Login PLUGIN>

Provide authentication: only for users in your ldap.

If you need external users see C<Jifty::Plugin::AuthLDAPLogin>

=head1 CONFIG

in etc/config.yml
  Plugins: 
    - AuthLDAPOnly: 
       LDAPhost: ldap1.univ-metz.fr     # ldap host
       LDAPbase: ou=people, ou=...      # ldap base
       LDAPuid: uid                     # optional

in your user model
  use base qw/Jifty::Plugin::AuthLDAPOnly::Model::LDAPUser/;

=head1 SEE ALSO

L<Net::LDAP>

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
