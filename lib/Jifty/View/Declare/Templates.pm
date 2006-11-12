use warnings;
use strict;
package Jifty::View::Declare::Templates;

use base qw/Exporter/;
use Template::Declare::Tags;

use base qw/Template::Declare/;
our @EXPORT = qw(form hyperlink tangent redirect new_action form_submit form_next_page request get);


sub form (&){
    my $code = shift;


    Jifty->web->form->start;
    outs($code->());
    Jifty->web->form->end;
}


sub hyperlink(@) {
    Jifty->web->link(@_);
}

sub tangent(@) {
    Jifty->web->tangent(@_);
}
sub redirect(@) {
    Jifty->web->redirect(@_);
}

sub new_action(@){
    Jifty->web->new_action(@_);
}

sub form_submit(@){
    Jifty->web->form->submit(@_);
}

sub form_next_page(@){
    Jifty->web->form->next_page(@_);
}

sub request {
    Jifty->web->request;
}

sub get {
    return map { request->argument($_) }  @_;
}

1;
