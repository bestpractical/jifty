use strict;
use warnings;

package Jifty::I18N;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon ();
use Email::MIME::ContentType;
use Encode::Guess qw(iso-8859-1);

=head1 NAME

Jifty::I18N - Internationalization framework for Jifty

=head1 METHODS

=head2 C<_>

This module exports the C<loc> method, which it inherits from
L<Locale::Maketext::Simple>. Jifty aliases this method to C<_()> for 
your convenience.

=cut


=head2 new

Set up Jifty's internationalization for your application.  This pulls
in Jifty's PO files, your PO files and then exports the _ function into
the wider world.

=cut


sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    Locale::Maketext::Lexicon->import(
        {   '*' => [
                Gettext => Jifty->config->framework('L10N')->{'PoDir'}
                    . '/*.po',
                Gettext => Jifty->config->framework('L10N')->{'DefaultPoDir'}
                    . '/*.po',
            ],
            _decode => 1,
            _auto   => 1,
            _style  => 'gettext',
        }
    );

    $self->init;

    # Allow hard-coded languages in the config file
    my $lang = Jifty->config->framework('L10N')->{'Lang'};
    $lang = [defined $lang ? $lang : ()] unless ref($lang) eq 'ARRAY';

    my $lh         = $class->get_handle(@$lang);
    my $loc_method = sub {
        # Retain compatibility with people using "-e _" etc.
        return \*_ unless @_;
        return undef unless (defined $_[0]);

        local $@;
        my $result = eval { $lh->maketext(@_) };
        if ($@) {
            # Sometimes Locale::Maketext fails to localize a string and throws
            # an exception instead.  In that case, we just return the input.
            return join(' ', @_);
        }
        return $result;
    };

    {
        no strict 'refs';
        no warnings 'redefine';
        *_ = $loc_method;
    }
    return $self;
}

=head2 promote_encoding STRING [CONTENT-TYPE]

Return STRING promoted to our best-guess of an appropriate
encoding. STRING should B<not> have the UTF-8 flag set when passed in.

Optionally, you can pass a MIME content-type string as a second
argument. If it contains a charset= parameter, we will use that
encoding. Failing that, we use Encode::Guess to guess between UTF-8
and iso-latin-1. If that fails, and the string validates as UTF-8, we
assume that. Finally, we fall back on returning the string as is.

=cut

# XXX TODO This possibly needs to be more clever and/or configurable

sub promote_encoding {
    my $class = shift;
    my $string = shift;
    my $content_type = shift;

    $content_type = Email::MIME::ContentType::parse_content_type($content_type) if $content_type;
    my $charset = $content_type->{attributes}->{charset} if $content_type;

    # XXX TODO Is this the right thing? Maybe we should just return
    # the string as-is.
    Encode::_utf8_off($string);

    if($charset) {
        $string = Encode::decode($charset, $string);
    } else {
        my $encoding = Encode::Guess->guess($string);
        if(!ref($encoding)) {
            eval {
                # Try utf8
                $string = Encode::decode_utf8($string, 1);
            };
            if($@) {
                warn "Unknown encoding -- none specified, couldn't guess, not valid UTF-8";
            }
        } else {
            $string = $encoding->decode($string) if $encoding;
        }
    }

    return $string;

}

1;
