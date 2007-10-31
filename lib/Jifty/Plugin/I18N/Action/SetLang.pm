package Jifty::Plugin::I18N::Action::SetLang;
use strict;
use DateTime::Locale ();

use base 'Class::Data::Inheritable';
__PACKAGE__->mk_classdata(_available_languages => undef);

use Jifty::Param::Schema;
use Jifty::Action schema {

param
    lang => label is _('Language'),
    render as 'select',
    default is defer { Jifty::I18N->get_current_language };
};

sub available_languages {
    my $class = shift;
    return $class->_available_languages if $class->_available_languages;

    $class->_available_languages(
        [   map { {   display => DateTime::Locale->load($_)->native_name,
                      value   => $_ } } Jifty::I18N->available_languages ] );
    return $class->_available_languages;
}

sub arguments {
    my $self = shift;
    my $args = $self->SUPER::arguments;

    # XXX: complete_native_name is way too long
    $args->{lang}->{valid_values} = $self->available_languages;

    return $args;
}

sub take_action {
    my $self = shift;
    my $lang = $self->argument_value('lang');
    Jifty->web->session->set(jifty_lang => $lang);

    Jifty::I18N->get_language_handle;

    $self->result->message(_("Hi, we speak %1.", DateTime::Locale->load($lang)->native_name));
}

1;
