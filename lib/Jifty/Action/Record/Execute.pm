use warnings;
use strict;

package Jifty::Action::Record::Execute;
use base qw/ Jifty::Action::Record /;

=head1 NAME

Jifty::Action::Record::Execute - Simple abstract based for record actions

=head1 SYNOPSIS

  use strict;
  use warnings;

  package MyApp::Action::StartEncabulator;
  use base qw/ MyApp::Action::ExecuteEncabulator /;

  use Jifty::Param::Schema;
  use Jifty::Action schema {
      param cardinal_grammeter_mode =>
          type is 'text',
          valid_values are qw/
              magneto-reluctance
              capacitive-duractance
              sinusoidal-depleneration
          /,
          is mandatory,
          ;
  }; 

  sub take_action {
      my $self = shift;

      my $mode = $self->argument_value('cardinal_grammeter_mode');
      $self->record->start($mode);

      $self->result->success('Deluxe Encabulator has started!');
  }

  # Later in your templates:
  my $encabulator = MyApp::Model::Encabulator->new;
  $encabulator->load($id);

  my $startup = Jifty->web->new_action( 
      class  => 'StartEncabulator',
      record => $encabulator,
  );

  Jifty->web->form->start;

  Jifty->web->out( $startup->form_field('cardinal_grammeter_mode') );

  Jifty->web->form->submit(
      label  => _('Start'),
      submit => $startup,
  );

  Jifty->web->form->end;

=head1 DESCRIPTION

This action class is a good generic basis for creating custom action classes. It expects a record object to be associated and is (in this way) very similar to L<Jifty::Action::Record::Delete>.

You can use L<Jifty::Param::Schema> to add additional form fields to the action and such.

=head1 METHODS

=head2 arguments

This is customized so that it expects the C<record> argument of all L<Jifty::Action::Record> actions, but also allows for overrides using L<Jifty::Param::Schema>.

=cut

# XXX TODO Copied from Jifty::Action::Record::Delete
sub class_arguments {
    my $self = shift;
    my $arguments = {};

    # Mark the primary key for use in the constructor and not rendered
    for my $pk (@{ $self->record->_primary_keys }) {
        $arguments->{$pk}{'constructor'} = 1;
        # XXX TODO IS THERE A BETTER WAY TO NOT RENDER AN ITEM IN arguments
        $arguments->{$pk}{'render_as'} = 'Unrendered'; 
        # primary key fields should always be hidden fields
    }
    return $arguments;
}

=head2 take_action

This overrides the definition in L<Jifty::Action::Record> so that it does absolutely nothing rather than complain. You will probably want to implement your own version that actually does something.

=cut

sub take_action {}

=head1 SEE ALSO

L<Jifty::Action>, L<Jifty::Action::Record>, L<Jifty::Record>

=head1 LICENSE

Jifty is Copyright 2005-2006 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
