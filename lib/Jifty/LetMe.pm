use warnings;
use strict;

package Jifty::LetMe;
use Digest::MD5;
use Math::BigInt;
use String::Koremutake;

use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors ( qw/checksum_provided email path args until user/);

=head1 NAME

Jifty::LetMe - A way to expose single-link URLs to your applications

=head2 new

Create a new "LetMe" authentication object

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

Easy initialization for local subclasses

=cut


sub _init { return shift }

=head2 user

Contains an app-specific "user" object that one can call 

=cut



=head2 currentuser_from_token

If the user has presented a valid token, returns an (app-specific subclass of the) L<Jifty::CurrentUser> 
object for the  user who has the email address in $self->email.
If no user has that email address, returns undef.

=cut

sub validated_current_user {
    my $self = shift;
    return undef unless ( $self->validate );
    return $self->_user_from_email($self->email);

}


=head2 _user_from_email ADDRESS

Returns an (app-specific subclass of the) L<Jifty::CurrentUser> object for the  user 
who has the email address ADDRESS.

=cut

sub _user_from_email {
    my $self = shift;
    my $email = shift;
    my $currentuser_object_class = Jifty->config->framework('CurrentUserClass');
    $currentuser_object_class->require;
    return $currentuser_object_class->new( email => $email );

}


=head2 generate_checksum

Returns an auth checksum for the current combination of

    user
    token
    until

=cut


sub generate_checksum {
    my $self = shift;

    # get user's generic secret
    my $user;
    return undef unless ( $user = $self->_user_from_email($self->email) );

    # build an md5sum of the email token and until and our secret
    my $digest = Digest::MD5->new();
    $digest->add( $user->auth_token );
    $digest->add( $self->path );
    my %args = %{$self->args};
    $digest->add( $_, $args{$_}) for sort keys %args;
    $digest->add( $self->until ) if ($self->until);
    # only take the first 16 characters. we're rally just trying to 
    # get something reasonably short, memorable and unguessable
    my $integer_digest = Math::BigInt->new("0x".substr($digest->hexdigest(),0,16));

    
    # the scary version:
    #my $integer_digest = Math::BigInt->new("0x". $digest->hexdigest() );

    # koremutake it
    my $k = String::Koremutake->new;
    return( $k->integer_to_koremutake($integer_digest));

}

=head2 from_token PATH

Parse a string of the form 

mylongusername@example.com/update_task/23/until/20050101/bekidrikufryvagygefuba

into 

     email => mylongusername@example.com,
      token => 'update_task/23'
      until => 20050101,
      checksum_provided => bekidrikufryvagygefuba
 




=cut

sub from_token {
    my $self = shift;
    my $token = shift;

    my @atoms = split('/',$token);

    $self->email( URI::Escape::uri_unescape( shift @atoms ) );
    $self->path( shift @atoms );
    $self->checksum_provided( pop @atoms );

    my %args = @atoms;
    $self->until( delete $args{until} ) if $args{until};
    
    $self->args(\%args);
}


=head2 as_token

Returns the "letme" token for this set of credentials. This should round
trip cleanly with from_token

=cut

=head2 as_encoded_token

A variant of as_token that encodes the user's email address suitably
for passing in a URL

=cut

sub as_token {
    my $self = shift;
    $self->_generate_token( email => $self->email );
}

sub as_encoded_token {
    my $self = shift;
    $self->_generate_token( email => URI::Escape::uri_escape($self->email) );
}

sub _generate_token {
    my $self = shift;
    my %args = (email => undef, @_);
    return join ('/', 
        $args{'email'},
        $self->path,
        %{$self->args},
        (defined $self->until ? ( 'until', $self->until ) : () ),
        $self->generate_checksum  
        );

}




=head2 as_url

Returns the fully qualified URL for this LetMe. It's composed of Jifty->web->url, $self->base_path and $self->as_encoded_token

=cut

sub as_url {
    my $self = shift;
    return Jifty->web->url . $self->base_path. $self->as_encoded_token;

}


=head2 base_path

By default, all  "LetMe" actions live at URLs under '/let' inside your application.
Override this subroutine to change that.

By default, it returns '/let'

=cut

sub base_path {
    return '/let/';

}


=head2 validate

Returns true if the credentials the user presented validate ok.
Returns false otherwise.

=cut

sub validate {
    my $self = shift;

    # email must exist

    unless ($self->_user_from_email($self->email)) {
        return undef;
    }

    unless ($self->path) {
        return undef;
    }
    unless ($self->checksum_provided) {
        return undef;
    }


    unless ($self->_correct_checksum_provided) {
        return undef;
    }

    return 1;
}


=head2 _correct_checksum_provided

Returns true if the checksum the user provided is correct. Doesn't actually
do much input checking. You want to call "validate"

=cut

sub _correct_checksum_provided {
    my $self = shift;
    return undef unless ($self->checksum_provided eq $self->generate_checksum); 

}

1;
