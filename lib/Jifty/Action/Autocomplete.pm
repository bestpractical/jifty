use warnings;
use strict;

=head1 NAME

Jifty::Action::Autocomplete

=head1 DESCRIPTION

A built-in Jifty action which returns suggested autocompletions 
for a given argument of an action. Generally this is called by
Jifty's internals through C</jifty/autocomplete.xml>.

This action gets its data to C<autocomplete.xml> by filling in a
L<Jifty::Result> object


=cut



package Jifty::Action::Autocomplete;
use base qw/Jifty::Action/;

=head2 new

By default, redirect actions happen as late as possible in the run
order.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return $self;
}

=head2 arguments

The arguments for C<Autocomplete> are:

=over 4

=item action

The moniker of an action we want to pull a field to autocomplete from

=item argument

The name of the argument to C<action> that we want to complete


=item preserve_helpers

=back

=cut

sub arguments {
        {
            action => {},
            argument => {}
        }

}

=head2 take_action

Go off and actually look up the possible completions

=cut

sub take_action {
    my $self = shift;

    my $moniker = $self->argument_value('action');
    # XXX TODO: we should just be getting the arg name, not the field name somehow
    my (undef, $arg_name, undef)  = Jifty->framework->request->parse_form_field_name($self->argument_value('argument'));

    my $request_action = Jifty->framework->request->action($moniker);
    my $action = Jifty->framework->new_action_from_request($request_action);

    my @completions = $action->autocomplete_argument($arg_name);
    #@completions = ( { label => 'foo', value => 'bar' });
    $self->result->content->{completions} = \@completions;

    return 1;
}

1;

