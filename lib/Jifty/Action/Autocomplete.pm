use warnings;
use strict;

=head1 NAME

Jifty::Action::Autocomplete

=head1 DESCRIPTION

A built-in L<Jifty::Action> which returns suggested autocompletions
for a given argument of an action. Generally this is called by Jifty's
internals through C</__jifty/autocomplete.xml>.

This action gets its data to C</__jifty/autocomplete.xml> by filling in the
C<completions> of the L<Jifty::Result/content>.

=cut



package Jifty::Action::Autocomplete;
use base qw/Jifty::Action/;

=head2 arguments

The arguments for C<Autocomplete> are:

=over 4

=item action

The L<moniker|Jifty::Manual::Glossary/moniker> of an action we want to pull a
field to autocomplete from.

=item argument

The fully qualified name of the L<argument|Jifty::Manual::Glossary/argument>
to C<action> that we want to complete.

=back

=cut

sub arguments {
    {
        action => {},
        argument => {}
    }
}

=head2 take_action

Find the submitted action in the L<Jifty::Request> named by the
C<action> above, and ask it for autocompletion possibilites for the
L<argument> in question.

=cut

sub take_action {
    my $self = shift;

    my $moniker = $self->argument_value('action');
    # XXX TODO: we should just be getting the arg name, not the field name somehow
    my (undef, $arg_name, undef)  = Jifty->web->request->parse_form_field_name($self->argument_value('argument'));

    my $request_action = Jifty->web->request->action($moniker);
    my $action = Jifty->web->new_action_from_request($request_action);

    my @completions = $action->_autocomplete_argument($arg_name);
    $self->result->content->{completions} = \@completions;

    return 1;
}

1;

