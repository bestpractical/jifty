use warnings;
use strict;
package Jifty::View::Declare::Templates;

use base qw/Exporter/;
use Template::Declare::Tags;

use base qw/Template::Declare/;
our @EXPORT = qw(form);


sub form (&){
    my $code = shift;


    Jifty->web->form->start;
    outs($code->());
    Jifty->web->form->end;
}


1;
