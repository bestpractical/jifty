use strict;
use warnings;

package Jifty::Plugin::I18N;
use base 'Jifty::Plugin';

=head1 NAME

Jifty::Plugin::I18N - Additional i18n facility such as language selector

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  L10N:
    PoDir: share/po
    AllowedLang:
      - en
      - zh_tw
  Plugins:
    - I18N:
        js: 1


=head1 DESCRIPTION

This plugin provides additional i18n facility to Jifty's core i18n
features, such as compiling l10n lexicon for client side javascript,
and a language selector action.

You will still need to manually do the following to make client side l10n work:

=over

=item Extract strings from your js files into your po file

  jifty po --dir share/web/static/js

=item Generate js dictionary

  jifty po --js

=back

=head2 init

=cut

__PACKAGE__->mk_accessors(qw/js/);

Jifty->web->add_javascript('loc.js');

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt  = @_;
    $self->js( $opt{js} );

    Jifty::Web->add_trigger(
        name      => 'after_include_javascript',
        callback  => sub { $self->_i18n_js(@_) },
    ) if $self->js;
}

sub _i18n_js {
    my $self = shift;

    my $current_lang = Jifty::I18N->get_current_language || 'en';

    # diagnosis for htf the client is requesting something not in allowed_lang.
    my $allowed_lang = Jifty->config->framework('L10N')->{'AllowedLang'};
    $allowed_lang = [defined $allowed_lang ? $allowed_lang : ()] unless ref($allowed_lang) eq 'ARRAY';

    if (@$allowed_lang) {
        my $allowed_regex = join '|', map {
            my $it = $_;
            $it =~ tr<-A-Z><_a-z>; # lc, and turn - to _
            $it =~ tr<_a-z0-9><>cd;  # remove all but a-z0-9_
            $it;
        } @$allowed_lang;

        unless ( $current_lang =~ /^$allowed_regex/) {
            $self->log->error("user is requesting $current_lang which is not allowed");
        }
    }

    if (
        open my $fh,
        '<:encoding(utf-8)',
        Jifty::Util->absolute_path(
            File::Spec->catdir(
                Jifty->config->framework('Web')->{StaticRoot},
                "js/dict/$current_lang.json"
            )
        )
      )
    {
        local $/;
        my $inline_dict = <$fh> || '{}';

        # js l10n init
        Jifty->web->out(
            qq{<script type="text/javascript">
Localization.dict_path = '/static/js/dict';
Localization.dict = $inline_dict;
</script>}
        );

    }
    else {
        $self->log->error("Can't find dictionary file $current_lang.json: $!");
    }

}

1;
