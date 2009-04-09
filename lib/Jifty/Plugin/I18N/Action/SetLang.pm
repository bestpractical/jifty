package Jifty::Plugin::I18N::Action::SetLang;
use strict;
use DateTime::Locale ();

use base 'Class::Data::Inheritable';
__PACKAGE__->mk_classdata(_available_languages => undef);

=head1 NAME

Jifty::Plugin::I18N::Action::SetLang - Sets user's current language

=head1 PARAMETERS

=head1 lang

The language to change to

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {

param
    lang => label is _('Language'),
    render as 'select',
    default is defer { Jifty::I18N->get_current_language };
};

=head1 METHODS

=head2 available_languages

Returns the list of possible internationalizations, as an array
reference suitable to pass to C<valid_values>.

=cut

sub available_languages {
    my $class = shift;
    return $class->_available_languages if $class->_available_languages;

    $class->_available_languages(
        [   map { {   display => DateTime::Locale->load($_)->native_name,
                      value   => $_ } } Jifty::I18N->available_languages ] );
    return $class->_available_languages;
}

=head2 arguments

Sets the valid values for C<lang> to L</available_languages>.

=cut

sub arguments {
    my $self = shift;
    my $args = $self->SUPER::arguments;

    # XXX: complete_native_name is way too long
    $args->{lang}->{valid_values} = $self->available_languages;

    return $args;
}

=head2 take_action

Alters the current session to use the given language.

=cut

sub take_action {
    my $self = shift;
    my $lang = $self->argument_value('lang');
    Jifty->web->session->set(jifty_lang => $lang);

    Jifty::I18N->get_language_handle;

    $self->result->message(_("Hi, we speak %1.", DateTime::Locale->load($lang)->native_name));
}

1;
