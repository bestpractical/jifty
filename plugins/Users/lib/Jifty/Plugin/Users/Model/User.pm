package Jifty::Plugin::Users::Model::User;
use base qw/Jifty::Record Jifty::Plugin::Users/;
use Jifty::DBI::Schema;

use Jifty::Record schema {
column
  display_name => type is 'text',
  label is 'Name',
  is mandatory;

column
  realm => type is 'text',
  label is 'Identity Plugin',
  is mandatory;

column
  created_date => type is 'date';

column
  updated_date => type is 'date';

column
  created_by => type is 'text';

column
  updated_by => type is 'text';

column
  last_login => type is 'date';

## ???
column
  auth_token => type is 'text',
  render_as 'Unrendered';
};


sub create {
    my $self  = shift;
    my %args  = (@_);
    my (@ret) = $self->SUPER::create(%args);
 # set  created_date and created_by
	return (@ret);
}

=head2 password_is STRING

Returns true if and only if the current user's password matches STRING

=cut

#sub password_is {
#    my $self   = shift;
#    my $string = shift;
#    return 1 if ( $self->_value('password') eq $string );
#    return 0;
#}

=head2 password

Never display a password

=cut

sub password {
    return undef;

}

=head2 current_user_can

Allows the current user to see all their own attributes and
everyone else to see their username.

Allows the current user to update any of their own attributes
except whether or not their email has been confirmed.

Passes everything else off to the superclass.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = (@_);
    # This line breaks admin mode. I like admin mode.
    #    Carp::confess if ( $right eq 'read' and not $args{'column'} );
    if (    $right eq 'read'
        and $self->id == $self->current_user->id )
    {
        return 1;
    }
    elsif ( $right eq 'read' and $args{'column'} eq 'display_name' ) {
        return (1);

    }
    elsif ( $right eq 'update'
        and $self->id == $self->current_user->id
#        and $args{'column'} ne 'email_confirmed' 
		)
    {
        return (1);
    }

    return $self->SUPER::current_user_can( $right, %args );
}

=head2 auth_token

Returns the user's unique authentication token. If the user 
doesn't have one, sets one and returns it.

=cut

sub auth_token {
    my $self = shift;
    return undef
      unless ( $self->current_user_can( read => column => 'auth_token' ) );
    my $value = $self->_value('auth_token');
    unless ($value) {
        my $digest = Digest::MD5->new();
        $digest->add( rand(100) );
        $self->__set( column => 'auth_token', value => $digest->b64digest );
    }
    return $self->_value('auth_token');

}

=head2 record_class

Identifies the correct record class for introspection

=cut

sub record_class {
    my $self = shift;
    return $self->UserClass;

}

1;
