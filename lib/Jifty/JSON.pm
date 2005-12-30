use warnings;
use strict;

package Jifty::JSON;

=head1 NAME

Jifty::JSON -- Wrapper around L<JSON>

=head1 DESCRIPTION

Provides a wrapper around the L<JSON> library.  The JSON specification
at L<http://www.crockford.com/JSON/> states that only double-quotes
are possible for specifying strings.  However, for the purposes of
embedding Javascript-compatible objects in XHTML attributes (which use
double-quotes), we sometimes want to provide strings in single quotes.
This provides a version of L<JSON/objToJson> which allows
single-quoted string output.

=head1 METHODS

=cut

use JSON ();

=head2 jsonToObj JSON, [ARGUMENTS]

For completeness, C<Jifty::JSON> provides a C<jsonToObj>.  It is
identical to L<JSON/jsonToObj>.

=cut

sub jsonToObj {
    return JSON::jsonToObj(@_);
}

=head2 objToJson OBJECT, [ARGUMENTS]

This method is identical to L<JSON/objToJson>, except it has an
additional possible option.  The C<singlequote> option, if set to a
true value in the C<ARGUMENTS> hashref, overrides L<JSON::Converter>'s
string output method to output single quotes as delimters instead of
double quotes.

=cut

# We should escape double-quotes somehow, so that we can guarantee
# that double-quotes *never* appear in the JSON string that is
# returned.
sub objToJson {
    my ($obj, $args) = @_;

    # Unless we're asking for single-quoting, just do what JSON.pm
    # does
    return JSON::Converter::objToJson($obj)
      unless delete $args->{singlequote};

    # Otherwise, insert our own stringify sub
    no warnings 'redefine';
    my %esc = (
        "\n" => '\n',
        "\r" => '\r',
        "\t" => '\t',
        "\f" => '\f',
        "\b" => '\b',
        "'"  => '\\\'',
        "\\" => '\\\\',
    );
    local *JSON::Converter::_stringfy = sub {
        my $arg = shift;
        $arg =~ s/([\\\n'\r\t\f\b])/$esc{$1}/eg;
        $arg =~ s/([\x00-\x07\x0b\x0e-\x1f])/'\\u00' . unpack('H2',$1)/eg;
        return "'" . $arg ."'";
    };
    return JSON::objToJson($obj, $args);
}

1;
