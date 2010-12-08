use warnings;
use strict;

package Jifty::JSON;

use base 'Exporter';
our @EXPORT_OK = qw/jsonToObj objToJson decode_json encode_json/;

use Carp qw//;
use JSON qw/ -support_by_pp -no_export /;

=head1 NAME

Jifty::JSON -- Wrapper around L<JSON>

=head1 SYNOPSIS

  use Jifty::JSON qw/decode_json encode_json/;

  my $obj  = decode_json(q! { "x": "1", "y": "2", "z": "3" } !);
  my $json = encode_json($obj);

=head1 DESCRIPTION

Provides a thin wrapper around the L<JSON> 2.xx library, which provides a
frontend for L<JSON::XS> and L<JSON::PP>.

This module used to wrap L<JSON::Syck> and L<JSON> 1.xx with special-casing for
outputting JSON with single quoted values.  Single quotes make it easy to
simply plop JSON into HTML attributes but are in violation of the JSON spec
which mandates only double quoted strings.

The old behavior is now unsupported and it is recommended that you simply HTML
escape your entire blob of JSON if you are sticking it in an HTML attribute.
You can use L<Jifty-E<gt>web-E<gt>escape()|Jifty::Web/escape> to properly
escape problematic characters for HTML.

=head1 FUNCTIONS

=head2 decode_json JSON, [ARGUMENT HASHREF]

=head2 encode_json JSON, [ARGUMENT HASHREF]

These functions are just like L<JSON>'s, except that you can pass options to
them like you can with L<JSON>'s C<from_json> and C<to_json> functions.

By default they encode/decode using UTF8 (like L<JSON>'s functions of the same
name), but you can turn that off by passing C<utf8 =E<gt> 0> in the
options.  The L<allow_nonref|JSON/allow_nonref> flag is also enabled for
backwards compatibility with earlier versions of this module.  It allows
encoding/decoding of values that are not references.

L<JSON> is imported with the C<-support_by_pp> flag in order to support all
options that L<JSON::PP> provides when using L<JSON::XS> as the backend.  If
you are concerned with speed, be careful what options you specify as it may
cause the pure Perl backend to be used.  Read L<JSON/JSON::PP SUPPORT METHODS>
for more information.

=cut

sub decode_json {
    JSON::from_json( $_[0], { utf8 => 1, allow_nonref => 1, %{$_[1] || {}} } );
}

sub encode_json {
    JSON::to_json( $_[0], { utf8 => 1, allow_nonref => 1, %{$_[1] || {}} } );
}

=head1 DEPRECATED FUNCTIONS

=head2 jsonToObj JSON, [ARGUMENTS]

=head2 objToJson JSON, [ARGUMENTS]

These functions are deprecated and provided for backwards compatibility.  They
wrap the appropriate function above, but L<Carp/croak> if you try to set the
C<singlequote> option.

=cut

sub jsonToObj {
    my $args = $_[1] || {};
    Carp::croak("Attempted to set 'singlequote' option, but it is no longer supported.".
                "  You may need to HTML escape the resulting JSON.".
                "  Please read the POD of Jifty::JSON and fix your code.")
        if exists $args->{'singlequote'};
    decode_json( @_ );
}

sub objToJson {
    my $args = $_[1] || {};
    Carp::croak("Attempted to set 'singlequote' option, but it is no longer supported.".
                "  You may need to HTML escape the resulting JSON.".
                "  Please read the POD of Jifty::JSON and fix your code.")
        if exists $args->{'singlequote'};
    encode_json( @_ );
}

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
