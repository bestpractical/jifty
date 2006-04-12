use warnings;
use strict;

package Jifty::Web::Form::Link;

=head1 NAME

Jifty::Web::Form::Link - Creates a state-preserving HTML link

=head1 DESCRIPTION

Describes an HTML link that may be AJAX-enabled.  Most of the
computation of this comes from L<Jifty::Web::Form::Clickable>, which
generates L<Jifty::Web::Form::Link>s.

=cut

use base qw/Jifty::Web::Form::Element Class::Accessor/;

=head2 accessors

Link adds C<url> and C<escape_label> to the list of possible accessors
and mutators, in addition to those offered by
L<Jifty::Web::Form::Element/accessors>.

=cut

sub accessors { shift->SUPER::accessors(), qw(url escape_label tooltip); }
__PACKAGE__->mk_accessors(qw(url escape_label tooltip));

=head2 new PARAMHASH

Creates a new L<Jifty::Web::Form::Link> object.  Possible arguments to
the C<PARAMHASH> are:

=over

=item url (optional)

The URL of the link; defaults to the current URL.

=item tooltip

Additional information about the link target.

=item escape_label

HTML escape the label and tooltip? Defaults to true

=item anything from L<Jifty::Web::Form::Element>

Any parameter which L<Jifty::Web::Form::Element/new> can take.

=back

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    my %args = (
        url          => $ENV{PATH_INFO},
        label        => "Click me!",
        tooltip      => undef,
        escape_label => 1,
        class        => '',
        @_
    );

    for my $field ( $self->accessors() ) {
        $self->$field( $args{$field} ) if exists $args{$field};
    }

    return $self;
}

=head2 url [URL]

Gets or sets the URL that the link links to.

=cut

=head2 render

Render the string of the link, including any necessary javascript.

=cut

sub render {
    my $self = shift;

    my $label = $self->label;
    $label = Jifty->web->mason->interp->apply_escapes( $label, 'h' )
        if ( $self->escape_label );

    my $tooltip = $self->tooltip;
    $tooltip = Jifty->web->mason->interp->apply_escapes( $tooltip, 'h' )
        if ( $tooltip and $self->escape_label );

    Jifty->web->out(qq(<a));
    Jifty->web->out(qq( id="@{[$self->id]}"))       if $self->id;
    Jifty->web->out(qq( class="@{[$self->class]}")) if $self->class;
    Jifty->web->out(qq( title="@{[$self->tooltip]}")) if $tooltip;
    Jifty->web->out(qq( href="@{[$self->url]}"));
    Jifty->web->out( $self->javascript() );
    Jifty->web->out(qq(>$label</a>));
    $self->render_key_binding();

    return ('');
}

1;
