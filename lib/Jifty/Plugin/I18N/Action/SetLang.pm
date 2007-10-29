package Jifty::Plugin::I18N::Action::SetLang;
use strict;
use DateTime::Locale ();

use Jifty::Param::Schema;
use Jifty::Action schema {

param lang =>
    label is _('Language'),
    render as 'select',
    # XXX: complete_native_name is way too long
    valid are defer {[ map { { display => DateTime::Locale->load($_)->native_name, value => $_ } } Jifty::I18N->available_languages ]},
    default is defer { Jifty::I18N->get_current_language };
};

sub take_action {
    my $self = shift;
    my $lang = $self->argument_value('lang');
    Jifty->web->session->set(jifty_lang => $lang);

    Jifty::I18N->get_language_handle;

    $self->result->message(_("Hi, we speak %1.", DateTime::Locale->load($lang)->native_name));
}

1;
