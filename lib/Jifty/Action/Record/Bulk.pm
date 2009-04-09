package Jifty::Action::Record::Bulk;

use warnings;
use strict;

=head1 NAME

Jifty::Action::Record::Bulk - Perform multiple record actions

=head1 SYNOPSIS

  use strict;
  use warnings;

  package MyApp::Action::BulkUpdateFoo;
  use base qw/ Jifty::Action::Record::Bulk /;

  __PACKAGE__->add_action('MyApp::Action::DeleteFoo' => { trigger => 'delete', final => 1 });
  __PACKAGE__->add_action('MyApp::Action::UpdateFoo');

=cut

use base qw/Jifty::Action::Record Class::Data::Inheritable/;

__PACKAGE__->mk_classdata( actions => [] );
__PACKAGE__->mk_classdata( record_class => undef );

use constant ids_name => 'ids';

=head1 METHODS

=head2 add_action CLASS [, OPTIONS]

Merges the given action class into this one.  Will C<die> if the
L<Jifty::Action::Record/action_class> of the given C<CLASS> doesn't
match previously added classes.

OPTIONS should be a hash reference of additional options.  The
existing options are:

=over

=item trigger

Only run if this argument is provided

=item final

If this action runs, run B<only> this action.

=back

=cut

sub add_action {
    my ($class, $name, $param) = @_;
    push @{$class->actions}, [ $name, $param ];
    Jifty::Util->require($name);
    if ($class->record_class) {
        die "$class is not a action of @{[ $class->record_class ]}"
            unless $class->record_class eq $name->record_class;
    }
    else {
        $class->record_class( $name->record_class );
    }
}

=head2 arguments

Merges together arguments from all of the actions added with
L</add_action>.  The record IDs to act on are stored (comma-separated)
in an argument named C<ids>, by default.

=cut

sub arguments {
    my $self = shift;
    my $arguments = { $self->ids_name => { render_as => 'text', sort_order => -999 } };

    # composite of the arguments from all actions, and remove the pk
    require Jifty::Param::Schema;

    for (@{$self->actions}) {
        my ($action_class, $param) = @$_;
        $arguments = Jifty::Param::Schema::merge_params( $arguments, $action_class->can('arguments')->($self) );
        delete $arguments->{id};
    }

    if ( $self->can('PARAMS') ) {
        $arguments = Jifty::Param::Schema::merge_params(
            $arguments, ($self->PARAMS || {})
        );
    }
    return $arguments;
}

=head2 perform_action CLASS, IDS

Performs the given action C<CLASS> on the given record C<ID>s, which
should be an array reference.

=cut

sub perform_action {
    my ($self, $action_class, $ids) = @_;
    $self->result->content('detailed_messages', {})
        unless $self->result->content('detailed_messages');

    for (@$ids) {
        my $record = $self->record_class->new;
        $record->load($_);

        my $action = $action_class->new(
            moniker => join('-', $self->moniker, $action_class, $_),
            record => $record,
            arguments => $self->argument_values );

        $action->take_action;
        $self->result->content('detailed_messages')->{ $action->moniker } = $action->result->message;
    }
    # allow bulk action to define if they allow individual action to fail
}

=head2 take_action

Completes the actions on all of the IDs given.

=cut

sub take_action {
    my $self = shift;
    my $ids = $self->argument_value('ids');
    # ids can be '0', and we don't want to keep '0'
    $ids = [ grep { $_ ne 0 } split /,/,$ids] if !ref($ids);
    for (@{$self->actions}) {
        my ($action_class, $param) = @$_;
        if (my $trigger = $param->{trigger}) {
            if ($self->argument_value($trigger)) {
                $self->perform_action($action_class, $ids);
                last if $param->{final};
            }
        }
        else {
            $self->perform_action($action_class, $ids);
        }
    }
}

=head2 report_success

Reports C<Bulk update successful>.

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Bulk update successful"));
}

1;

