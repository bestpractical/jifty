package Jifty::Web::Form::Field::Wikitext;
use warnings;
use strict;
use base qw/Jifty::Web::Form::Field::Textarea/;

use Text::WikiFormat;

__PACKAGE__->mk_accessors(qw(rows cols));

=head1 NAME

Jifty::Web::Form::Field::Wikitext - A textarea that renders wiki syntax

=head2 canonicalize_value

Renders the value using L<Text::WikiFormat>.

=cut


sub render_value {
    my $self  = shift;
    my $field = '<span';
    $field .= qq! class="@{[ $self->classes ]} value"> !;
    if (defined $self->current_value) {
        my $text = "@{[$self->current_value]}";
        # XXX: scrub html out of $text

        $field .= Text::WikiFormat::format($text, {}, {
            extended       => 1,
            absolute_links => 1,
            implicit_links => 0, # XXX: make this configurable
            prefix         => Jifty->web->url,
        });
    }
    $field .= qq!</span>\n!;
    Jifty->web->out($field);
    return '';
}

1;

