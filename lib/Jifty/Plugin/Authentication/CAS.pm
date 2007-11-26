use strict;
use warnings;

package Jifty::Plugin::Authentication::CAS;
use base qw/Jifty::Plugin/;
use Authen::CAS::Client;

=head1 NAME

Jifty::Plugin::Authentication::CAS

=head1 DESCRIPTION

This may be combined with the L<Jifty::Plugin::User> plugin to provide user authentication using JA-SIG CAS protocol to your application.

https is managed with Crypt::SSLeay

=head1 CONFIG

 in etc/config.yml

  Plugins: 
    - Authentication::CAS: 
       CASUrl: https://auth.univ-metz.fr/cas
       CASDomain: univ-metz.fr                  # optional: create email if login@domain is valid


=head1 METHODS

=head2 prereq_plugins

This plugin depends on the L<User|Jifty::Plugin::User> plugin.

=cut


sub prereq_plugins {
    return ('User');
}


my ($CAS,$domain);

=head2 init

load config 

=cut

sub init {
    my $self = shift;
    my %args = @_;

    $CAS = Authen::CAS::Client->new ( $args{'CASUrl'} );
    $domain = $args{'CASDomain'} || "" ;
};


sub CAS {
    return $CAS;
};

sub domain {
    return $domain;
};

=head1 TODO

add a ldap config to get more attributes

=head1 SEE ALSO

L<Jifty::Manual::AccessControl>, L<Jifty::Plugin::User>, L<Authen::CAS::Client>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
