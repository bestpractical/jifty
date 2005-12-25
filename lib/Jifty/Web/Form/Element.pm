use warnings;
use strict;
 
package Jifty::Web::Form::Element;

=head1 NAME

Jifty::Web::Form::Element - Web input of some sort

=head1 DESCRIPTION

Describes any HTML element that might live in a form.

=cut

use base qw/Jifty::Object Class::Accessor/;

sub handlers { qw(onclick); }

sub accessors { shift->handlers }
__PACKAGE__->mk_accessors(qw(onclick));

=head2 javascript

=cut

sub javascript {
    my $self = shift;
    
    my $response = "";
    for my $trigger ($self->handlers) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = ref $value eq "ARRAY" ? @{$value} : ($value);
        $response .= " $trigger=\"";
        for my $hook (@hooks) {
            if ($hook->{submit}) {
                $response .= qq!var a = new Action('@{[$hook->{submit}]}'); a.submit();!;
            }

            $response .= qq!update_region(!;

            # Region
            $response .= qq!'@{[$hook->{region} || Jifty->framework->qualified_region]}'!;

            # Arguments
            my %these = ( (map {($_->key, $_->value)} Jifty->framework->request->state_variables), %{$hook->{args} || {}});
            $response .= qq!,{!;
            $response .= join(',', map {($a = $these{$_}) =~ s/'/\\'/g; "'$_':'$a'"} keys %these);
            $response .= qq!}!;

            # Fragment (optional)
            $response .= qq!,'@{[$hook->{fragment}]}'!
              if $hook->{fragment};

            $response .= qq!);!;
        }
        $response .= "return false;\"";
    }
    return $response;
}

1;
