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

use base 'Jifty::Web::Form::Element';

# Since we don't inherit from Form::Field, we don't otherwise stringify.
# We need the anonymous sub because otherwise the method of the base class is
# always called, instead of the appropriate overridden method in a possible
# child class.
use overload '""' => sub { shift->render }, bool => sub { 1 };

=head2 accessors

Link adds C<url> and C<escape_label> to the list of possible accessors
and mutators, in addition to those offered by
L<Jifty::Web::Form::Element/accessors>.

=cut

sub accessors { shift->SUPER::accessors(), qw(url escape_label tooltip target rel); }
__PACKAGE__->mk_accessors(qw(url escape_label tooltip target rel));

=head2 new PARAMHASH

Creates a new L<Jifty::Web::Form::Link> object.  Possible arguments to
the C<PARAMHASH> are:

=over

=item url (optional)

The URL of the link; defaults to the current URL.

=item tooltip

Additional information about the link.

=item target

Target of the link.  Mostly useful when specified as "_blank" to open
a new window or as the name of a already existing window.

=item escape_label

HTML escape the label and tooltip? Defaults to true

=item anything from L<Jifty::Web::Form::Element>

Any parameter which L<Jifty::Web::Form::Element/new> can take.

=back

=cut

sub new {
    my $class = shift;
    my $args = ref($_[0]) ? $_[0] : {@_};
    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;
    my $self  = $class->SUPER::new(
      { url          => $root,
        label        => "Click me!",
        tooltip      => undef,
        escape_label => 1,
        class        => '',
        rel          => '',
        target       => '' }, $args );

    return $self;
}

=head2 url [URL]

Gets or sets the URL that the link links to.

=cut

=head2 as_string

Returns the string of the link, including any necessary javascript.

=cut

sub as_string {
    my $self = shift;
    my $label = $self->label;
    my $web = Jifty->web;
    $label = $web->escape( $label )
        if ( $self->escape_label );

    my $tooltip = $self->tooltip;
    $tooltip = $web->escape( $tooltip )
        if ( defined $tooltip and $self->escape_label );

    my $output = '';

    $output .= (qq(<a));
    $output .= (qq( id="@{[$self->id]}"))         if $self->id;
    $output .= (qq( class="@{[$self->class]}"))   if $self->class;
    $output .= (qq( title="@{[$tooltip]}"))       if defined $tooltip;
    $output .= (qq( target="@{[$self->target]}")) if $self->target;
    $output .= (qq( accesskey="@{[$self->key_binding]}")) if $self->key_binding;
    $output .= (qq( rel="@{[$self->rel]}"))       if $self->rel;
    $output .= (qq( href="@{[$web->escape($self->url)]}"));
    $output .= ( $self->javascript() );
    $output .= (qq(>$label</a>));

    $output .= (
        '<script type="text/javascript">' .
        $self->key_binding_javascript.
        "</script>") if $self->key_binding;

    return $output;
}

=head2 render

Render the string of the link, including any necessary javascript.

=cut

sub render {
    my $self = shift;

    Jifty->web->out($self->as_string);
    return ('');
}

1;
