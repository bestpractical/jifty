use strict;
use warnings;

package Jifty::Plugin::I18N;
use base 'Jifty::Plugin';

=head1 NAME

Jifty::Plugin::I18N

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

This plugin provides additional i18n facility to jifty's core i18n
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

__PACKAGE__->mk_accessors(qw(js));

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

    # js l10n init
    my $current_lang = Jifty::I18N->get_current_language || 'en';
    Jifty->web->out(qq{<script type="text/javascript">Localization.init({dict_path: '/static/js/dict', lang: '$current_lang'});</script>});
}

1;
