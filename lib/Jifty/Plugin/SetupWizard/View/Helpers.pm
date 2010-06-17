package Jifty::Plugin::SetupWizard::View::Helpers;
use strict;
use warnings;
use Jifty::View::Declare -base;

sub config_field {
    my $self = shift;
    my %args = @_;

    my $action = new_action('AddConfig');

    my %value_args = %{ $args{value_args} || {} };

    # Grab a sensible default, the current value of config
    if (!exists($value_args{default_value})) {
        $value_args{default_value} = Jifty->config->contextual_get($args{context}, $args{field});
    }

    # Grab sensible label, the value of field
    if (!exists($value_args{label})) {
        $value_args{label} = $args{field};
    }

    outs_raw($action->form_field('value' => %value_args));

    for my $field (qw/field context target_file message empty_is_undef/) {
        outs_raw($action->form_field(
            $field,
            render_as => 'hidden',
            (exists($args{$field}) ? (default_value => $args{$field}) : ()),
        ));
    }

    return $action;
}

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard::View::Helpers - Helper templates and functions for SetupWizard

=head1 FUNCTIONS

=head2 config_field

A helper function for constructing a mini-form for a config field. It returns
the action that was created. Expected arguments are:

=over 4

=item value_args

The arguments for the C<form_field> call for value. If there's no C<default_value>, one will be constructed using the C<context> parameter.

=item field

=item context

=item target_file

=item message

=item empty_is_undef

These parameters are for specifying defaults for each action argument.

=back

=cut

