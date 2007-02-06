use warnings;
use strict;
package Jifty::View::Declare::Helpers;

use base qw/Exporter/;
use Template::Declare::Tags;

use base qw/Template::Declare/;
our @EXPORT = (qw(form hyperlink tangent redirect new_action form_submit form_next_page request get set render_param current_user render_action render_region ), @Template::Declare::Tags::EXPORT);

{
no warnings qw/redefine/;
sub form (&){
    my $code = shift;
    outs_raw(Jifty->web->form->start);
    $code->();
    outs_raw(Jifty->web->form->end);
    return ''
}
}

sub hyperlink(@) {
    outs_raw(Jifty->web->link(@_));
    return '';
}

sub tangent(@) {
    outs_raw(Jifty->web->tangent(@_));
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
    Template::Declare->new_buffer_frame;
    Jifty::Web::PageRegion->new(@_)->render;
    my $content = Template::Declare->buffer->data();
    Template::Declare->end_buffer_frame;
    Jifty->web->out($content);
}

sub render_action(@){
    my ($action, $fields, $field_args) = @_;
    my @f = $fields && @$fields ? @$fields : $action->argument_names;
    foreach my $argument (@f) {
        outs_raw($action->form_field($argument, %$field_args));
    }
}

sub form_submit(@){
    outs_raw( Jifty->web->form->submit(@_));
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
    if (wantarray) {
        map { request->argument($_) }  @_;
    }
    else {
        request->argument($_[0]);
    }
}

sub set {
    while (my ($arg, $val) = (shift @_, shift @_)){ 
    request->argument($arg => $val);
    }

}


sub render_param {
    my $action = shift;
    outs_raw($action->form_field(@_));
    return '';
}

1;
