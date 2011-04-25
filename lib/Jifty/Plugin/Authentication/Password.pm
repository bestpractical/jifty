use strict;
use warnings;

package Jifty::Plugin::Authentication::Password;
use base qw/Jifty::Plugin/;

__PACKAGE__->mk_accessors(qw/nav_menu/);

=head1 NAME

Jifty::Plugin::Authentication::Password - password authentication plugin

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - LetMe: {}
    - User: {}
    - Authentication::Password:
        login_by: email

# we now support two login_by: email or username

=head1 DESCRIPTION

B<CAUTION:> This plugin is experimental.

This may be combined with the L<Jifty::Plugin::User> and
L<Jifty::Plugin::LetMe> plugins to provide user accounts and
form-based password authentication to your application.

=head2 METHODS

=head2 prereq_plugins

This plugin depends on the L<User|Jifty::Plugin::User> and L<LetMe|Jifty::Plugin::LetMe> plugins.

=cut


sub prereq_plugins {
    return ('User', 'LetMe');
}

=head2 init 

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt  = ( nav_menu => 1,
                 @_ );

    $self->nav_menu( $opt{nav_menu} );
}

=head1 SEE ALSO

L<Jifty::Manual::AccessControl>, L<Jifty::Plugin::User>, L<Jifty::Plugin::LetMe>, L<Jifty::Plugin::Authentication::Password::Mixin::Model::User>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
