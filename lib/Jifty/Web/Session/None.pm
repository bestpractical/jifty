package Jifty::Web::Session::None;

use warnings;
use strict;

=head1 NAME

Jifty::Web::Session::None - A null session handler for jifty

=head1 DESCRIPTION

Jifty depends on its sessions to keep users logged in, to store
continuations and to allow developers to store user-specific data.
In general, you don't want to disable them. But sometimes, the
development benefits of Jifty lead you to build applications that
genuinely don't want per-user sessions. That's where 
C<Jifty::Web::Session::None> comes in. By specifying that you want
to use C<Jifty::Web::Session::None> as your Jifty session handler, 
you tell Jifty to avoid ever reading, writing or storing a user session.
No cookies get set. Nothing gets stored in the database.

=head1 USAGE

In your C<etc/config.yml>:

 ---
 framework:
   Web:
     SessionClass:: Jifty::Web::Session::None
 
=cut

=head1 METHODS

All methods in this class are dummy methods which do no work. This class
mocks the API provided by C<Jifty::Web::Session>.

=cut

=head2 new

Takes no arguments. Returns a L<Jifty::Web::Session::None>.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 id

Returns false.

=cut

sub id {return undef }

=head2 create

Returns true.

=cut

sub create { return 1}

=head2 load

Returns true.

=cut

sub load { return 1}

=head2 unload

Returns true.

=cut

sub unload { return 1}

=head2 loaded

Returns true.

=cut

sub loaded { return 1};

=head2 get

Returns false.

=cut

sub get { return undef;}

=head2 set

Returns false.

=cut

sub set { return undef;}

=head2 remove

Returns true.

=cut

sub remove { return 1}

=head2 set_continuation

Returns false.

=cut
sub set_continuation { return undef}

=head2 get_continuation

Returns false.

=cut

sub get_continuation {return undef}

=head2 remove_continuation

Returns false.

=cut

sub remove_continuation {return undef}

=head2 continuations

Returns false.

=cut

sub continuations { return undef}

=head2 set_cookie

Returns false.

=cut

sub set_cookie { return undef}

=head2 cookie_name

Returns false.

=cut

sub cookie_name { return undef}

=head2 expires

Returns false.

=cut

sub expires {return undef}

1;
