use warnings;
use strict;

package Jifty::Web::Form::Element;

=head1 NAME

Jifty::Web::Form::Element - Some item that can be rendered in a form

=head1 DESCRIPTION

Describes any HTML element that might live in a form, and thus might
have javascript on it.

Handlers are placed on L<Jifty::Web::Form::Element> objects by calling
the name of the javascript event handler, such as C<onclick>, with a
set of arguments.

The format of the arguments passed to C<onclick> (or any similar method)
is a hash reference, with the following possible keys:

=over

=item submit (optional)

An action (or moniker of an action) to be submitted when the event is fired.

=item region (optional)

The region that should be updated.  This defaults to the current
region.

=item args (optional)

Arguments to the region.  These will override the default arguments to
the region.

=item fragment (optional)

The fragment that should go into the region.  The default is whatever
fragment the region was originally rendered with.

=back

=cut

use base qw/Jifty::Object Class::Accessor/;

=head2 handlers

Currently, the only supported event handlers are C<onclick>.

=cut

sub handlers { qw(onclick); }

=head2 accessors

Any descendant of L<Jifty::Web::Form::Element> should be able to
accept any of the event handlers (above) as one of the keys to its
C<new> parameter hash.

=cut

sub accessors { shift->handlers, qw(class key_binding id label) }
__PACKAGE__->mk_accessors(qw(onclick class key_binding id label ));

=head2 javascript

Returns the javsscript necessary to make the events happen.

=cut

sub javascript {
    my $self = shift;

    my $response = "";
    for my $trigger ( $self->handlers ) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = ref $value eq "ARRAY" ? @{$value} : ($value);
        $response .= " $trigger=\"";
        for my $hook (@hooks) {

            $response .= qq!update_region({!;

            # Region
            $response
                .= qq!name: '@{[$hook->{region} || Jifty->web->qualified_region]}'!;

            # Submit action
            if ( $hook->{submit} ) {
                my $moniker = ref $hook->{submit}
                    ? $hook->{submit}->moniker
                    : $hook->{submit};
                $response .= qq!, submit: '@{[$moniker]}'!;
            }

            # Arguments
            my %these = ( %{ $hook->{args} || {} } );
            $response .= qq!, args: {!;
            $response .= join( ',',
                map { ( $a = $these{$_} ) =~ s/'/\\'/g; "'$_':'$a'" }
                    keys %these );
            $response .= qq!}!;

            # Fragment (optional)
            $response .= qq!, fragment: '@{[$hook->{fragment}]}'!
                if $hook->{fragment};

            $response .= qq!});!;
        }
        $response .= "return false;\"";
    }
    return $response;
}

=head2 class

Sets the CSS class that the element will display as

=head2 key_binding

Sets the key binding associated with this elements

=head2 id

Subclasses must override this to provide each element with a unique id.

=head2 label

Sets the label of the element.  This will be used for the key binding
legend, at very least.

=head2 render_key_binding

Adds the key binding for this input, if one exists.

=cut

sub render_key_binding {
    my $self = shift;
    my $key  = $self->key_binding;
    if ($key) {
        Jifty->web->mason->out( "<script><!--\naddKeyBinding(" . "'"
                . uc($key) . "', "
                . "'click', " . "'"
                . $self->id . "'," . "'"
                . $self->label . "'"
                . ");\n-->\n</script>\n" );
    }
}

1;
