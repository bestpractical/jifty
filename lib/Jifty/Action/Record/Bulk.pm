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

  use constant record_class => 'MyApp::Model::Foo';

  __PACKAGE__->add_action('MyApp::Action::DeleteFoo' => { trigger => 'delete', final => 1 });
  __PACKAGE__->add_action('MyApp::Action::UpdateFoo');

=head1 DESCRIPTION

=cut

use base qw/Jifty::Action::Record Class::Data::Inheritable/;

__PACKAGE__->mk_classdata( actions => [] );
__PACKAGE__->mk_classdata( record_class => undef );

use constant ids_name => 'ids';

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

sub take_action {
    my $self = shift;
    my $ids = $self->argument_value('ids');
    $ids = [split /,/,$ids] if !ref($ids);
    for (@{$self->actions}) {
        my ($action_class, $param) = @$_;
        # XXX: create real action objects and invoke them, so we have separate result objects

        # $action_class->new( record => $loaded, arguments => ..., moniker => ... );
        # collect action->result object for reporting, index by content of the current action

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

sub report_success {
    my $self = shift;
    $self->result->message(_("yatta"));
}

1;

