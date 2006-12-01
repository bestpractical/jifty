use warnings;
use strict;
package Jifty::View::Declare::Templates;

use base qw/Exporter/;
use Template::Declare::Tags;

use base qw/Template::Declare/;
our @EXPORT = qw(form hyperlink tangent redirect new_action form_submit form_next_page request get param current_user render_action render_region);

{
no warnings qw/redefine/;
sub form (&){
    my $code = shift;
    outs(Jifty->web->form->start);
    $code->();
    outs(Jifty->web->form->end);
    return ''
}
}

sub hyperlink(@) {
    outs (Jifty->web->link(@_));
    return '';
}

sub tangent(@) {
    outs (Jifty->web->tangent(@_));
    return '';
}
sub redirect(@) {
    Jifty->web->redirect(@_);
    return ''
}

sub new_action(@){
    return Jifty->web->new_action(@_);
}

sub render_region(@){
    unshift @_, 'name' if @_ % 2;
    Jifty::Web::PageRegion->new(@_)->render;
}

sub render_action(@){
    my ($action, $fields, $field_args) = @_;
    my @f = $fields && @$fields ? @$fields : $action->argument_names;
    foreach my $argument (@f) {
        outs($action->form_field($argument, %$field_args));
    }
}

sub form_submit(@){
    outs( Jifty->web->form->submit(@_));
    '';
}

sub form_next_page(@){
    Jifty->web->form->next_page(@_);
}

sub request {
    Jifty->web->request;
}

sub current_user {
    Jifty->web->current_user;
}

sub get {
    return map { request->argument($_) }  @_;
}

sub param {
    my $action = shift;
    outs($action->form_field(@_));
    return '';
}

1;
