package TestApp::Model::User;
use warnings;
use strict;
use base qw/TestApp::Record/;
use Jifty::DBI::Schema;
use Scalar::Defer;

# Your column definitions go here.  See L<Jifty::DBI::Schema> for
# documentation about how to write column definitions.
use Jifty::Record schema  {
column 'name' =>
  type is 'text',
  label is _('Name'),
  hints is _('I18N test'),
  is mandatory;
column 'email' =>
  type is 'text',
  is mandatory;
column 'really_tasty' =>
  type is 'boolean',
  is immutable,
  since '0.0.2';
column 'tasty' =>
  type is 'boolean',
  is immutable,
  till '0.0.2';
column 'password' =>
  type is 'text',
  render_as 'Password',
  is mandatory,
  default is '';
column 'created_on' =>
  type is 'datetime',
  is immutable,
  default is defer { DateTime->now },
  filters are qw/Jifty::Filter::DateTime Jifty::DBI::Filter::Date/;
};


# Your model-specific methods go here.

sub current_time
{
    Jifty::DateTime->now();
}

sub time_zone
{
    'America/Anchorage'
}

sub current_user_can {
    my $self = shift;
    my $right = shift;
    my %args = @_;

    return 1 if $self->SUPER::current_user_can($right => %args);
    
    return 1 if $self->current_user->id and $self->id and $self->current_user->id == $self->id;

    return 0;
}

1;

