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

sub canonicalize_value {
    my $self = shift;
    my $text = shift;

    return Text::WikiFormat::format($text);
}

1;

