use warnings;
use strict;

package Jifty::Action::Record::Update;

=head1 NAME

Jifty::Action::Record::Update - Automagic update action

=head1 DESCRIPTION

This class is used as the base class for L<Jifty::Action>s that are
merely updating L<Jifty::Record> objects.  To use it, subclass it and
override the C<record_class> method to return the name of the
L<Jifty::Record> subclass that this action should update.

=cut

use base qw/Jifty::Action::Record/;

=head1 METHODS

=head2 arguments

Overrides the L<Jifty::Action::Record/arguments> method to further
specify that all of the primary keys B<must> have values when
submitted; that is, they are
L<constructors|Jifty::Manual::Glossary/constructors>.

=cut

sub arguments {
    my $self = shift;
    my $arguments = $self->SUPER::arguments(@_);

    for my $column ( $self->record->columns ) {
        if ( not $column->writable and $column->readable ) {
            $arguments->{$column->name}{'render_mode'} = 'read';
        }
    }

    for my $pk (@{ $self->record->_primary_keys }) {
        $arguments->{$pk}{'constructor'} = 1;
        $arguments->{$pk}{'mandatory'} = 1;
        # XXX TODO IS THERE A BETTER WAY TO NOT RENDER AN ITEM IN arguments
        $arguments->{$pk}{'render_as'} = 'Unrendered'; 
        # primary key fields should always be hidden fields
    }
    return $arguments;
}

=head2 validate_arguments

We only need to validate arguments that got B<submitted> -- thus, a
mandatory argument that isn't submitted isn't invalid, as it's not
going to change the record.  This is opposed to the behavior inherited
from L<Jifty::Action>, where mandatory arguments B<must> be present
for the action to run.

However, constructor arguments are still required.

=cut

sub _validate_arguments {
    my $self = shift;

    $self->_validate_argument($_) for grep {
        $self->has_argument($_)
            or $self->arguments->{$_}->{constructor}
    } $self->argument_names;

    return $self->result->success;
}

=head2 take_action

Overrides the virtual C<take_action> method on L<Jifty::Action> to
call the appropriate C<Jifty::Record>'s C<set_> methods when the
action is run, thus updating the object in the database.

=cut

sub take_action {
    my $self = shift;
    my $changed = 0;

    for my $field ( $self->argument_names ) {
        # Skip values that weren't submitted
        next unless $self->has_argument($field);

        my $column = $self->record->column($field);

        # Skip nonexistent fields
        next unless $column;

        # Grab the value
        my $value = $self->argument_value($field);

        # Boolean and integer fields should be skipped if blank.
        # (This logic should be moved into SB or something.)
        next
            if ( defined $column->type and ( $column->type =~ /^bool/i || $column->type =~ /^int/i )
            and defined $value and $value eq '' );

        # Skip file uploads if blank
        next if lc $self->arguments->{$field}{render_as} eq "upload"
          and (not defined $value or not ref $value);

        if (ref $value eq "Fh") { # CGI.pm's "lightweight filehandle class"
            local $/;
            binmode $value;
            $value = scalar <$value>;
        }

        # Skip fields that have not changed
        my $old = $self->record->$field;
        # XXX TODO: This ignore "by" on columns
        $old = $old->id if ref($old) and $old->isa( 'Jifty::Record' );
    
        # if both the new and old values are defined and equal, we don't want to change em
        # XXX TODO "$old" is a cheap hack to scalarize datetime objects
        next if ( defined $old and defined $value and "$old" eq "$value" );

        # If _both_ the values are ''
        next if (  (not defined $old or not length $old)
                    and ( not defined $value or not length $value ));

        my $setter = "set_$field";
        my ( $val, $msg ) = $self->record->$setter( $value );
        $self->result->field_error($field, $msg)
          if not $val and $msg;

        $changed = 1 if $val;
    }

    $self->report_success
      if $changed and not $self->result->failure;

    return 1;
}

=head2 report_success

Sets the L<Jifty::Result/message> to default success message,
"Updated". Override this if you want to report some other more
user-friendly result.

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Updated"))
}

1;
