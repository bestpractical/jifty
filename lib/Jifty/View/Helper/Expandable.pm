use warnings;
use strict;

package Jifty::View::Helper::Expandable;
use base qw/Jifty::View::Helper/;

__PACKAGE__->mk_accessors(qw(element label));

=head1 STATE

L<Jifty::View::Helper::Expandable> objects have a state variable called
C<expanded>.

=head1 METHODS


=head2 new

Creates a new helper.  Should take the following named arguments:
C<moniker> (interpreted by L<Jifty::View::Helper>), C<label> (the text of the
link to expand the expandable), and C<element> (a L<Jifty::Callback> which is
called if the expandable is expanded).

=cut
sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  my %args = (
    label => undef,
    element => undef,
    @_
  ); 
  
  $self->label($args{'label'});
  $self->element($args{'element'});

  return $self;
}

=head2 element [VALUE]

Gets or sets the element.

=head2 label [VALUE]

Gets or sets the label.

=cut


=head2 render

Either C<call>s its C<element> or makes a link to expand it.

=cut

sub render {
    my $self = shift;
    if ( $self->state('expanded') ) {
        $self->element->call;
    }
    else {
        my $query_args = Jifty->framework->query_string(
            Jifty->framework->request->clone->add_helper(
                moniker => $self->moniker,
                class   => ref($self),
                states  => { expanded => 1 },
                )->helpers_as_query_args
        );
        my $label = HTML::Entities::encode_entities( $self->label );
        Jifty->mason->out(
            qq{<a href="@{[ Jifty->mason->{top_path} ]}?$query_args">$label</a>}
        );
    }
    return '';
}

1;

