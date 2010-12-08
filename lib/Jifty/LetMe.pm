use warnings;
use strict;

package Jifty::LetMe;
use Digest::MD5 ();
use Math::BigInt::Calc;
use String::Koremutake ();

use base qw/Jifty::Object Class::Accessor::Fast/;

__PACKAGE__->mk_accessors ( qw/checksum_provided email path args until user/);

=head1 NAME

Jifty::LetMe - A way to expose single-link URLs to your applications

=head2 new

Create a new "LetMe" authentication object; it takes no parameters.
It calls L</_init> to do any initialization.

A LetMe is a way to provide a one-time-use URL for a particular purpose.
All LetMe objects give you a way to validate a user's identity and to
allow them a very small set of possible actions or page-access permissions.

For example, you can put a LetMe URL in an email to a new user,
so that when they click on the URL you know that their email address
is valid.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->args({});
    $self->_init(@_);
    return $self;

}

=head2 _init @_

Called with whatever L</new> was called with.  By default, does nothing.

=cut

sub _init { return shift }

=head2 user

Contains an app-specific "user" object.

=cut

=head2 validated_current_user

If the user has presented a valid token, returns an (app-specific
subclass of the) L<Jifty::CurrentUser> object for the user who has the
email address in $self->email.  If no user has that email address,
returns undef.

=cut

sub validated_current_user {
    my $self = shift;
    return undef unless ( $self->validate );
    my $currentuser = Jifty->app_class("CurrentUser");
    return Jifty->app_class('CurrentUser')->new( email => $self->email );

}


=head2 _user_from_email ADDRESS

Returns an (app-specific subclass of the) L<Jifty::CurrentUser> object
for the user who has the email address I<ADDRESS>.

=cut

sub _user_from_email {
    my $self = shift;
    my $email = shift;
    my $currentuser_object_class = Jifty->app_class("CurrentUser");
    my $u = $currentuser_object_class->new( email => $email )->user_object;
    # we want to be able to get at their auth token.
    $u->current_user( $currentuser_object_class->superuser );
    return $u;
}

sub _generate_digest {
    my $self = shift;

    # get user's generic secret
    my $user;
    return '' unless ( $user = $self->user || $self->_user_from_email($self->email) );
    return '' unless ($user->auth_token);


    # build an md5sum of the email token and until and our secret
    my $digest = Digest::MD5->new();
    $digest->add( $user->auth_token );
    $digest->add( $self->path );
    my %args = %{$self->args};
    $digest->add( Encode::encode_utf8($_), Encode::encode_utf8($args{$_})) for sort keys %args;
    $digest->add( $self->until ) if ($self->until);
    return $digest->hexdigest();
}



=head2 generate_checksum

Returns an authentication checksum for the current combination of:

    user
    path
    arguments
    until

=cut

sub generate_checksum {
    my $self = shift;

    return substr( $self->_generate_digest, 0, 16 );
}

=head2 generate_koremutake_checksum

Generate a slightly more pronounceable version of the checksum using
L<String::Koremutake>.  Due to hex -> integer limitations, this is
imprecise and may vary depending on the platform it is used on; as
such, it is deprecated.

=cut

sub generate_koremutake_checksum {
    my $self = shift;

    # Only take the first 16 characters. We're really just trying to
    # get something reasonably short, memorable and unguessable. Also,
    # don't use Math::BigInt->new directly for simple computation,
    # because it insists exporting overload to us, which makes
    # devel::cover and devel::dprof very sad.  This is deprecated in
    # favor of generate_checksum, which returns a straight hex digest.
    my $integer_digest = Math::BigInt::Calc->_str(
        Math::BigInt::Calc->_from_hex(
            substr( $self->_generate_digest, 0, 16 )
        )
    );

    # koremutake it.  This loses precision, since most perls can't
    # deal with 64 bits with precision.  Thus, $integer_digest ends up
    # being rounded, possibly in unpredicatable ways.
    my $k = String::Koremutake->new;
    return( $k->integer_to_koremutake($integer_digest));

}

=head2 from_token PATH

Parse a string of the form 

mylongusername@example.com/update_task/23/until/20050101/bekidrikufryvagygefuba

into 

      email => mylongusername@example.com,
      path  => 'update_task/23'
      until => 20050101,
      checksum_provided => bekidrikufryvagygefuba

=cut

sub from_token {
    my $self = shift;
    my $token = shift;

    my @atoms = split('/',$token);

    $self->email( Jifty::I18N->maybe_decode_utf8(URI::Escape::uri_unescape( shift @atoms )) );
    $self->path( shift @atoms );
    $self->checksum_provided( pop @atoms );

    # If they don't even have the right number of items in the path, then we know that it's not valid
    return undef unless (scalar @atoms % 2 == 0); 

    my %args = map { Jifty::I18N->maybe_decode_utf8(URI::Escape::uri_unescape($_)) } @atoms;
    $self->until( delete $args{until} ) if $args{until};

    $self->args(\%args);
}


=head2 as_token

Returns the "letme" token for this set of credentials. This should round
trip cleanly with from_token

=cut

sub as_token {
    my $self = shift;
    $self->_generate_token( email => $self->email );
}

=head2 as_encoded_token

A variant of as_token that encodes the user's email address suitably
for passing in a URL

=cut

sub as_encoded_token {
    my $self = shift;
    $self->_generate_token( email => URI::Escape::uri_escape_utf8($self->email) );
}

sub _generate_token {
    my $self = shift;
    my %args = (email => undef, @_);
    return  join ('/', 
        $args{'email'},
        $self->path,
        (map {URI::Escape::uri_escape_utf8($_)} %{$self->args}),
        (defined $self->until ? ( 'until', $self->until ) : () ), #?
        $self->generate_checksum  
        );
}


=head2 as_url

Returns the fully qualified URL for this LetMe. It's composed of
Jifty->web->url, L</base_path> and L</as_encoded_token>

=cut

sub as_url {
    my $self = shift;
    return Jifty->web->url(path => $self->base_path . $self->as_encoded_token);

}


=head2 base_path

By default, all "LetMe" actions live at URLs under '/let' inside your
application.  Override this subroutine to change that.

By default, it returns '/let/'

=cut

sub base_path {
    return '/let/';

}


=head2 validate

Returns true if the credentials the user presented validate OK.
Returns false otherwise.

=cut

sub validate {
    my $self = shift;

    # email must exist

    unless ($self->_user_from_email($self->email)) {
        $self->log->debug("Token validation failed - Invalid user");
        return undef;
    }

    unless ($self->path) {
        $self->log->debug("Token validation failed - Invalid path");
        return undef;
    }
    unless ($self->checksum_provided) {
        $self->log->debug("Token validation failed - Checksum not provided");
        return undef;
    }


    unless ($self->_correct_checksum_provided) {
        $self->log->debug("Token validation failed - Checksum not correct");
        return undef;
    }

    return 1;
}


=head2 _correct_checksum_provided

Returns true if the checksum the user provided is correct. Doesn't
actually do much input checking. You want to call "validate"

=cut

sub _correct_checksum_provided {
    my $self = shift;
    $self->log->debug("LetMe checksum: ".$self->checksum_provided . " vs ". $self->generate_checksum );
    return undef
        unless ( $self->checksum_provided eq $self->generate_checksum )
        or
        ( $self->checksum_provided eq $self->generate_koremutake_checksum );

    return 1;
}

1;
