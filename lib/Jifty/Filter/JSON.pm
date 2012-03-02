use strict;
use warnings;

package Jifty::Filter::JSON;
use base qw/ Jifty::DBI::Filter /;
use Jifty::JSON qw(encode_json decode_json);

=head1 NAME

Jifty::Filter::JSON - This filter stores arbitrary Perl via JSON

=head1 SYNOPSIS

  use Jifty::DBI::Record schema {
      column my_data =>
          type is 'text',
          filters are qw/ Jifty::Filter::JSON /;
  };

  my $thing = __PACKAGE__->new;
  $thing->create( my_data => { foo => 'bar', baz => [ 1, 2, 3 ] } );

  my $my_data = $thing->my_data;
  while (my ($key, $value) = %$my_data) {
      # do something...
  }

=head1 DESCRIPTION

This filter provides the ability to store arbitrary data structures into a database column using L<JSON>. This is very similar to the L<Jifty::DBI::Filter::Storable> filter except that the L<JSON> format remains human-readable in the database. You can store virtually any Perl data, scalar, hash, or array into the database using this filter. 

In addition, JSON (at least the storage of scalars, hashes, and arrays) is compatible with data structures written in other languages, so you may store or read data between applications written in different languages.

=head1 METHODS

=head2 encode

This method is used to encode the Perl data structure into JSON formatted text.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $$value_ref = encode_json($$value_ref);
}

=head2 decode

This method is used to decode the JSON formatted text from the database into the Perl data structure.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $$value_ref = decode_json($$value_ref);
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<Jifty::JSON>

=head1 AUTHOR

Luke Closs E<lt>cpan@5thplane.comE<gt>

=head1 LICENSE

This program is free software and may be modified or distributed under the same terms as Perl itself.

=cut

1
