use warnings;
use strict;

package Jifty::JSON;

use base 'Exporter';
our @EXPORT_OK = qw/jsonToObj objToJson/;

=head1 NAME

Jifty::JSON -- Wrapper around L<JSON>

=head1 SYNOPSIS

  use Jifty::JSON qw/jsonToObj objToJson/;

  # Even though you might be using JSON::Syck, use the original JSON names
  my $obj  = jsonToObj(q! { 'x': 1, 'y': 2, 'z': 3 } !);
  my $json = objToJson($obj);

=head1 DESCRIPTION

Provides a wrapper around the L<JSON> library.

The JSON specification at L<http://www.json.org/> states that only
double-quotes are possible for specifying strings.  However, for the purposes
of embedding Javascript-compatible objects in XHTML attributes (which use
double-quotes), we sometimes want to provide strings in single quotes.
This provides a version of L<JSON/objToJson> which allows
single-quoted string output.

If the faster L<JSON::Syck> is available, it is preferred over the pure-perl
L<JSON>, as it provides native support for single-quoted strings.

=head1 METHODS

=cut

BEGIN {
    # Errors that happen here, stay here.
    local $@;

    # We're hacking, so tell the nannies to leave for a minute
    no strict 'refs';
    no warnings 'once';

    # If a good version of JSON::Syck is available use that...
    if (eval { require JSON::Syck; JSON::Syck->VERSION(0.05) }) {
        *jsonToObj = *_jsonToObj_syck;
        *objToJson = *_objToJson_syck;
        $JSON::Syck::ImplicitUnicode = 1;
    }

    # Bummer, fallback to the pure Perl implementation
    else {
        require JSON;
        *jsonToObj = *_jsonToObj_pp;
        *objToJson = *_objToJson_pp;
        $JSON::UTF8 = 1;
    }
}

=head2 jsonToObj JSON, [ARGUMENTS]

For completeness, C<Jifty::JSON> provides a C<jsonToObj>.  It is
identical to L<JSON/jsonToObj>.

=cut

sub _jsonToObj_syck {
    local $JSON::Syck::SingleQuote = 0;
    JSON::Syck::Load($_[0]);
}

sub _jsonToObj_pp {
    return JSON::jsonToObj(@_);
}

=head2 objToJson OBJECT, [ARGUMENTS]

This method is identical to L<JSON/objToJson>, except it has an
additional possible option.  The C<singlequote> option, if set to a
true value in the C<ARGUMENTS> hashref, overrides L<JSON::Converter>'s
string output method to output single quotes as delimters instead of
double quotes.

=cut

sub _objToJson_syck {
    my ($obj, $args) = @_;

    local $JSON::Syck::SingleQuote = $args->{singlequote};
    local $JSON::Syck::ImplicitUnicode = 1;
        my $json = JSON::Syck::Dump($obj);
        if (! $args->{singlequote}) {
                $json =~ s/\n\n\n/\\n/gs;       # fix syck bug
                $json =~ s/\n/\\n/gs;           # just to be safe
                $json =~ s/\r/\\r/gs;
        }
        return $json;
}

# We should escape double-quotes somehow, so that we can guarantee
# that double-quotes *never* appear in the JSON string that is
# returned.
sub _objToJson_pp {
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
        $arg =~ s/([\x00-\x07\x0b\x0e-\x1f])/'\\u00' . unpack('H2',$1)/egs;
        return "'" . $arg ."'";
    };
    return JSON::objToJson($obj, $args);
}

=head1 LICENSE

Jifty is Copyright 2005-2006 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
