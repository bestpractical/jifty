use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::Signup - signup for an account

=cut

package Jifty::Plugin::Authentication::Password::Action::Signup;
our @ISA;
{
    my $class = Jifty->app_class('Action', 'CreateUser');
    push @ISA, $class;
}

=head2 arguments


The fields for C<Signup> are:

=over 4

=item email: the email address

=item password and password_confirm: the requested password

=item name: your full name

=back

=cut

sub class_arguments {
    my $self = shift;
    my $args = $self->SUPER::class_arguments();

    my %fields = (
        name             => 1,
        email            => 1,
        password         => 1,
        password_confirm => 1,
    );

    for (keys %$args){
        delete $args->{$_} unless $fields{$_};
    }

    $args->{'email'}{'ajax_validates'}   = 1;
    $args->{'email'}{'mandatory'}        = 1;
    $args->{'name'}{'ajax_validates'}   = 1;
    $args->{'password_confirm'}{'label'} = _("Type that again?");
    return $args;
}

=head2 validate_email

Make sure their email address looks sane

=cut

sub validate_email {
    my $self  = shift;
    my $email = shift;
    my $LoginUser   = Jifty->app_class('Model', 'User');
    my $CurrentUser   = Jifty->app_class('CurrentUser');


    return $self->validation_error( email => _("That doesn't look like an email address.") ) unless ( $email =~ /\S\@\S/ );

    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols( email => $email );
    if ( $u->id ) {
        return $self->validation_error( email => _('It looks like you already have an account. Perhaps you want to <a href="/login">log in</a> instead?')
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
    my $LoginUser   = Jifty->app_class('Model', 'User');
    my $CurrentUser   = Jifty->app_class('CurrentUser');
        
    my $record = $LoginUser->new( current_user => $CurrentUser->superuser );

    my %values;
    $values{$_} = $self->argument_value($_) for grep {
        defined $self->record->column($_) and defined $self->argument_value($_)
    } $self->argument_names;

    my ($id, $msg) = $record->create(%values);

    # Handle errors?
    unless ( $record->id ) {
        $self->result->error( _("Something bad happened and we couldn't create your account: %1", $msg).' '.  _("Try again later. We're really, really sorry.")
        );
        return;
    }

    $self->result->message( _("Welcome to %1, %2.", Jifty->config->framework('ApplicationName'), $record->name)
          . ' ' . _("We've sent a confirmation message to your email box.") );

    return 1;
}

1;
