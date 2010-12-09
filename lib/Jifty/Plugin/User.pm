use strict;
use warnings;

package Jifty::Plugin::User;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::User - Plugin for building user models

=head1 DESCRIPTION

This plugin provides a "user" mixin for your application's user model
class.  Use this plugin if you want to use Jifty's authentication
framework.

=head1 SEE ALSO

L<Jifty::Manual::AccessControl>,
L<Jifty::Plugin::User::Mixin::Model::User>,
L<Jifty::Plugin::Authentication::Password>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
