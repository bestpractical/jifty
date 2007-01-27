package Jifty::Plugin::AuthCASOnly::Model::CASUser;
use base qw/Jifty::Record/;
use Jifty::DBI::Schema;
use Scalar::Defer;

use Jifty::Record schema {
column
  name => type is 'text',
  label is 'Name',
  is mandatory,
  is distinct;

column 'created_on' =>
  type is 'datetime',
  is immutable,
  default is defer { DateTime->now },
  filters are 'Jifty::DBI::Filter::DateTime';
};


sub create {
    my $self  = shift;
    my %args  = (@_);
    my (@ret) = $self->SUPER::create(%args);

#    if ( $self->id and not $self->email_confirmed ) {
#        Jifty::Plugin::Login::Notification::ConfirmAddress->new( to => $self )
#          ->send;
#    }
    return (@ret);
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
    elsif ( $right eq 'read' and $args{'column'} eq 'name' ) {
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

1;
