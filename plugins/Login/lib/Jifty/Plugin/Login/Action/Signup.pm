use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Login::Action::Signup

=cut

package Jifty::Plugin::Login::Action::Signup;
use Jifty::Plugin::Login::Action::CreateUser;
use base qw/Jifty::Plugin::Login::Action::CreateUser Jifty::Plugin::Login/;

=head2 arguments


The fields for C<Signup> are:

=over 4

=item email: the email address

=item password and password_confirm: the requested password

=item name: your full name

=back

=cut

sub arguments {
    my $self = shift;
    my $args = $self->SUPER::arguments;

    my %fields = (
        name             => 1,
        email            => 1,
        password         => 1,
        password_confirm => 1,
    );

    for ( keys %$args ) { delete $args->{$_} unless ( $fields{$_} ); }
    $args->{'email'}{'ajax_validates'}   = 1;
    $args->{'password_confirm'}{'label'} = "Type that again?";
    return $args;
}

=head2 validate_email

Make sure their email address looks sane

=cut

sub validate_email {
    my $self  = shift;
    my $email = shift;
    my $LoginUser = $self->LoginUserClass();
    my $CurrentUser = $self->CurrentUserClass();

    return $self->validation_error(
        email => "That doesn't look like an email address." )
      unless ( $email =~ /\S\@\S/ );

    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols( email => $email );
    if ( $u->id ) {
        return $self->validation_error( email =>
'It looks like you already have an account. Perhaps you want to <a href="/login">sign in</a> instead?'
        );
    }

    return $self->validation_ok('email');
}

=head2 take_action

Overrides the virtual C<take_action> method on L<Jifty::Action> to call
the appropriate C<Jifty::Record>'s C<create> method when the action is
run, thus creating a new object in the database.

Makes sure that the user only specifies things we want them to.

=cut

sub take_action {
    my $self   = shift;
    my $LoginUser = $self->LoginUserClass();
    my $CurrentUser = $self->CurrentUserClass();
    my $record = $LoginUser->new( current_user => $CurrentUser->superuser );

    my %values;
    $values{$_} = $self->argument_value($_) for grep {
        defined $self->record->column($_) and defined $self->argument_value($_)
    } $self->argument_names;

    my ($id) = $record->create(%values);

    # Handle errors?
    unless ( $record->id ) {
        $self->result->error(
"Something bad happened and we couldn't create your account.  Try again later. We're really, really sorry."
        );
        return;
    }

    $self->result->message( "Welcome to "
          . Jifty->config->framework('ApplicationName') . ", "
          . $record->name
          . ". We've sent a confirmation message to your email box." );

    return 1;
}

1;
