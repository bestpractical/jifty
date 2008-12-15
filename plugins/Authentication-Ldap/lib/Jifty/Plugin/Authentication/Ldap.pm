use strict;
use warnings;

package Jifty::Plugin::Authentication::Ldap;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::Authentication::Ldap - LDAP Authentication Plugin

=head1 DESCRIPTION

B<CAUTION:> This plugin is experimental.

This may be combined with the L<User|Jifty::Plugin::User::Mixin::Model::User>
Mixin to provide user accounts and ldap password authentication to your
application.

When a new user authenticates using this plugin, a new User object will be created
automatically.  The C<name> and C<email> fields will be automatically populated
with LDAP data.

in etc/config.yml

  Plugins: 
    - Authentication::Ldap: 
       LDAPhost: ldap.univ.fr           # ldap server
       LDAPbase: ou=people,dc=.....     # base ldap
       LDAPName: displayname            # name to be displayed (cn givenname)
       LDAPMail: mailLocalAddress       # email used optionnal
       LDAPuid: uid                     # optional


Then create a user model

  jifty model --name=User

and edit lib/App/Model/User.pm to look something like this:

  use strict;
  use warnings;
  
  package Venice::Model::User;
  
  use Jifty::DBI::Schema;
  use Venice::Record schema {
	# More app-specific user columns go here
  };
  
  use Jifty::Plugin::User::Mixin::Model::User;
  use Jifty::Plugin::Authentication::Ldap::Mixin::Model::User;
  
  sub current_user_can {
      my $self = shift;
      my $type = shift;
      my %args = (@_);
      
    return 1 if
          $self->current_user->is_superuser;
    
    # all logged in users can read this table
    return 1
        if ($type eq 'read' && $self->current_user->id);
    
    return $self->SUPER::current_user_can($type, @_);
  };
  
  1;

=head2 ACTIONS

This plugin will add the following actions to your application.
For testing you can access these from the Admin plugin.

=over

=item Jifty::Plugin::Authentication::Ldap::Action::LDAPLogin

The login path is C</ldaplogin>.

=item Jifty::Plugin::Authentication::Ldap::Action::LDAPLogout

The logout path is C</ldaplogout>.

=back

=cut

=head2 METHODS

=head2 prereq_plugins

This plugin depends on the L<User|Jifty::Plugin::User::Mixin::Model::User> Mixin.

=cut


sub prereq_plugins {
    return ('User');
}

use Net::LDAP;


my ($LDAP, %params);

=head2 Configuration

The following options are available in your C<config.yml>
under the Authentication::Ldap Plugins section.

=over

=item C<LDAPhost>

Your LDAP server.

=item C<LDAPbase>

The base object where your users live.

=item C<LDAPMail>

The DN that your organization uses to store Email addresses.  This
gets copied into the User object as the C<email>.

=item C<LDAPName>

The DN that your organization uses to store Real Name.  This gets
copied into the User object as the C<name>.

=item C<LDAPuid>

The DN that your organization uses to store the user ID.  Usually C<cn>.
This gets copied into the User object as the C<ldap_id>.

=item C<LDAPOptions>

These options get passed through to L<Net::LDAP>.

Default Options :

 debug   => 0
 onerror => undef
 async   => 1 

Other options you may want :
 
 timeout => 30

See C<Net::LDAP> for a full list.  You can overwrite the defaults
selectively or not at all.

=back

=cut

sub init {
    my $self = shift;
    my %args = @_;

    $params{'Hostname'} = $args{LDAPhost};
    $params{'base'}     = $args{LDAPbase} or die "Need LDAPbase in plugin config";
    $params{'uid'}      = $args{LDAPuid}     || "uid";
    $params{'email'}    = $args{LDAPMail}    || "";
    $params{'name'}     = $args{LDAPName}    || "cn";
    my $opts            = $args{LDAPOptions} || {};

    # Default options for Net::LDAP
    $opts->{'debug'}   = 0       unless defined $opts->{'debug'};
    $opts->{'onerror'} = 'undef' unless defined $opts->{'onerror'};
    $opts->{'async'}   = 1       unless defined $opts->{'async'};
    $params{'opts'}    = $opts;

    $LDAP = Net::LDAP->new($params{Hostname},%{$opts})
        or die "Can't connect to LDAP server ",$params{Hostname};
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
};

sub name {
    return $params{'name'};
};

sub opts {
    return $params{'opts'};
};


sub get_infos {
    my ($self,$user) = @_;

    my $result = $self->LDAP()->search (
            base   => $self->base(),
            filter => '(uid= '.$user.')',
            attrs  =>  [$self->name(),$self->email()],
            sizelimit => 1
             );
    $result->code && Jifty->log->error( 'LDAP uid=' . $user . ' ' . $result->error );
    my ($ret) = $result->entries;
    my $name = $ret->get_value($self->name());
    my $email = $ret->get_value($self->email());

    return ({ name => $name, email => $email });
};



=head1 SEE ALSO

L<Jifty::Manual::AccessControl>, L<Jifty::Plugin::User::Mixin::Model::User>, L<Net::LDAP>

=head1 LICENSE

Jifty is Copyright 2005-2008 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
