use strict;
use warnings;

=head1 NAME

Jifty::Plugin::AuthzLDAP - Jifty plugin to a add dynamic ldap authorization

=head1 DESCRIPTION

Jifty plugin.
Provide ldap authorization with filters table and cache.

=head1 CONFIGURATION NOTES

in etc/config.yml
  Plugins: 
    - AuthzLDAP: 
       LDAPbind: cn=testldap,ou=admins,dc=myorg,dc=org #
       LDAPpass: test                   # password
       LDAPhost: ldap.myorg.org         # ldap host
       LDAPbase: ou=people,dc=myorg..   # ldap base
       LDAPuid: uid                     # optional
       CacheTimout: 20                  # minutes, optional, default 20 minutes

in application create a LDAPFilter model
        use base qw/Jifty::Plugin::AuthzLDAP::Model::LDAPFilter/;

in LDAPFilter model create your filters, something like
 name    |filter                         |is_group
 is_admin|(!eduPersonAffiliation=STUDENT)|0
 in_admin|cn=admin,ou=groups,dc=my.org   |1

to protect access to /admin
in "TestApp" application create a lib/TestApp/Dispatcher.pm 

    use strict;
    use warnings;

    package TestApp::Dispatcher;
    use Jifty::Dispatcher -base;

    before '/admin/*' => run {
       # Authentication
       Jifty->web->tangent(url => '/login')
            if (! Jifty->web->current_user->id);
       # Authorization
       my $user = Jifty->web->current_user->user_object->name;
       Jifty->web->tangent(url => '/error/AccessDenied')
            if (! Jifty::Plugin::AuthzLDAP->ldapvalidate($user,'is_admin') );
    };

    1

=head1 SEE ALSO

L<Net::LDAP>

=cut


package Jifty::Plugin::AuthzLDAP;
use base qw/Jifty::Plugin/;

our $VERSION = '0.02';

use Net::LDAP;
use Cache::MemoryCache;

{
    my ($LDAPFilterClass, $LDAP, $cache, %params);

=head1 METHODS

=head2 init

load config parameters, connect to ldap, create memory cache

=cut

    sub init {
        my $self = shift;
        my %args = @_;

        my $appname = Jifty->config->framework('ApplicationName');
        $LDAPFilterClass = "Jifty::Plugin::AuthzLDAP::Model::LDAPFilter";

        $params{'Hostname'} = $args{LDAPhost};
        $params{'base'} = $args{LDAPbase};
        $params{'uid'} = $args{LDAPuid} || "uid";
        $params{'dn'} = $args{LDAPbind};
        $params{'pass'} = $args{LDAPpass};
        $params{'timeout'} = $args{CacheTimout} || "20 minutes";

        $LDAP = Net::LDAP->new($params{Hostname},async=>1,onerror => 'undef', debug => 0);

        $cache = new Cache::MemoryCache( { 'namespace' => $appname.'AuthzLDAP',
                                            'default_expires_in' => $params{'timeout'} } );
    }

=head2 BASE CACHE DN  LDAP BASE UID PASS LDAPFilterClass

accesors to conf parametres

=cut

    sub LDAPFilterClass {
        return $LDAPFilterClass;
    }

    sub LDAP {
        return $LDAP;
    }

    sub DN {
        return $params{'dn'};
    }

    sub PASS {
        return $params{'pass'};
    }

    sub UID {
        return $params{'uid'};
    }

    sub BASE {
        return $params{'base'};
    }
    
    sub CACHE {
        return $cache;
    }

}

=head2 bind

Bind to ldap

=cut

sub bind {
    my $self = shift;
    my $msg = $self->LDAP()->bind($self->DN() ,'password' =>$self->PASS());
    unless (not $msg->code) {
        Jifty->log->error("Bind to ldap server failed"); 
        return;
    }
}

=head2 ldapvalidate NAME FILTERNAME

return 1 if NAME validate FILTER or NAME-FILTERNAME in cache
else return 0

If FILTERNAME is flagged as is_group, search if user is uniquemember of this group
as supported by the Netscape Directory Server

=cut

sub ldapvalidate {
    my ($self, $user, $filtername) = @_;
    my $response  = 'nok';
    
    my $cachekey = $user.'-'.$filtername;
    my $cache = $self->CACHE->get($cachekey);
    return ($cache eq 'ok')?1:0 if (defined $cache);
   
    my $record = $self->LDAPFilterClass()->new();
    $record->load_by_cols( name => $filtername);

    # (?) allow use of writing filter in filtername
    # TODO: filtername must be cleanned
    # my $filter = ($record->filter)?$record->filter:$filtername;
    my $filter = $record->ldapfilter;

    $user = $self->UID().'='.$user.','.$self->BASE();
    
    # (??) how to catch AuthLDAP bind if it's used?
    $self->bind();

    my $msg;
    # manage group as supported by the Netscape Directory Server 
    if ($record->is_group) {
        $msg = $self->LDAP()->compare( $filter, attr=>"uniquemember", value=>$user );
        Jifty->log->debug("search grp: ".$msg->code); 
        $response = 'ok' if ( $msg->code == 6 );
    } else {
            $filter = '('. $filter .')' if ( $filter !~ /^\(/ );
            $msg = $self->LDAP()->search( base => $user, filter => $filter );
            Jifty->log->debug("search: ".$msg->count); 
            $response = 'ok' if (! $msg->code &&  $msg->count );
    }

    $self->CACHE->set($cachekey,$response);

    return ( $response eq 'ok' )?1:0; 
}

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2007-2008 Yves Agostini. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
