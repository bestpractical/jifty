use strict;
use warnings;

package Jifty::Plugin::Authentication::Ldap;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::Authentication::Ldap - ldap authentication plugin

=head1 DESCRIPTION

B<CAUTION:> This plugin is experimental.

This may be combined with the L<Jifty::Plugin::User> plugin to provide user accounts and ldap password authentication to your application.

in etc/config.yml

  Plugins: 
    - Login: {}
    - Authentication::Ldap: 
       LDAPhost: ldap.univ.fr           # ldap server
       LDAPbase: ou=people,dc=.....     # base ldap
       LDAPName: displayname            # name to be displayed (cn givenname)
       LDAPMail: mailLocalAddress       # email used optionnal
       LDAPuid: uid                     # optional



=head2 METHODS

=head2 prereq_plugins

This plugin depends on the L<User|Jifty::Plugin::User> plugin.

=cut


sub prereq_plugins {
    return ('User');
}

use Net::LDAP;


my ($LDAP, %params);

=head2 init

read etc/config.yml

=cut

sub init {
    my $self = shift;
    my %args = @_;

    $params{'Hostname'} = $args{LDAPhost};
    $params{'base'} = $args{LDAPbase};
    $params{'uid'} = $args{LDAPuid} || "uid";
    $params{'email'} = $args{LDAPMail} || "";
    $params{'name'} = $args{LDAPName} || "cn";
    $LDAP = Net::LDAP->new($params{Hostname},async=>1,onerror => 'undef', debug => 0);
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



sub get_infos {
    my ($self,$user) = @_;

    my $result = $self->LDAP()->search (
            base   => $self->base(),
            filter => '(uid= '.$user.')',
            attrs  =>  [$self->name(),$self->email()],
            sizelimit => 1
             );
    my ($ret) = $result->entries;
    my $name = $ret->get_value($self->name());
    my $email = $ret->get_value($self->email());

    return ({ name => $name, email => $email });
};



=head1 SEE ALSO

L<Jifty::Manual::AccessControl>, L<Jifty::Plugin::User>, L<Net::LDAP>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
