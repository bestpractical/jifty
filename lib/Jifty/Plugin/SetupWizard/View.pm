package Jifty::Plugin::SetupWizard::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

my $plugin = Jifty->find_plugin('Jifty::Plugin::SetupWizard');

unless ( $plugin->opts->{'nodefault'} ) {
    use Jifty::Plugin::SetupWizard::View::Generic;
    alias Jifty::Plugin::SetupWizard::View::Generic
          under '/__jifty/admin/setupwizard';
}

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard::View - templates for SetupWizard

=head1 FUNCTIONS

=head2 step_link

A helper function for constructing a link to a different step. Expected
arguments: the C<index> of the step and the C<label> for the link.

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

