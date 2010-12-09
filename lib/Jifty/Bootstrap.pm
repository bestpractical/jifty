use warnings;
use strict;

package Jifty::Bootstrap;

use base qw/Jifty::Object/;

=head1 NAME

Jifty::Bootstrap - Insert initial data into your database

=head1 DESCRIPTION

C<Jifty::Bootstrap> is an abstract base class for your application's
bootstrapping.  Use it to set up initial data in your database when
your application is first installed.

=head1 EXAMPLE
 
 package MyApp::Bootstrap;
 use base 'Jifty::Bootstrap';
 
 sub run {
     my $user = MyApp::CurrentUser->new( _bootstrap => 1);
     my $modelclass = MyApp::Model::Thingy->new(current_user => $user);
     $modelclass->create( name => 'Widget');
 }; 
 
=head2 run

C<run> is the workhorse method for the Bootstrap class.  This takes care of
setting up internal data structures and initializing things in an
application-dependent manner.

=cut

sub run { 
    1;
}

=head1 SEE ALSO

L<Jifty::Upgrade>, L<Jifty::Script::Schema>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
