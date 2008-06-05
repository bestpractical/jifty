package Jifty::Script::ModPerl2;
use strict;
use warnings;

use Apache2::Const -compile => qw(OK);
use Jifty::Everything;
use CGI;

# XXX: can we turn it into a command line script and at the same time use it as
# as handler?

=head1 NAME

Jifty::Script::ModPerl2 - a ModPerl2 handler for your jifty app.

=head1 SYNOPSIS

    <VirtualHost *:80>
        DocumentRoot /path/to/base/dir/of/app
        SetHandler perl-script
        PerlHandler Jifty::Script::ModPerl2
    </VirtualHost>

Not a command line script. Read --man for more info.

=head1 DESCRIPTION

This handler should be used with Apache2 and ModPerl2.  It requires the
DocumentRoot of its VirtualHost to be set to the base directory of your
jifty application.

Here is the relevant minimal httpd.conf section:

  <VirtualHost *:80>
    DocumentRoot /path/to/base/dir/of/app
    SetHandler perl-script
    PerlHandler Jifty::Script::ModPerl2
  </VirtualHost>

It would not necessarily need to be a VirtualHost- could be a Directory,
and should configure about the same.

TODO: This should be set up to serv the static files without mod_perl.

=head1 METTHODS

=head2 handler

The mod_perl handler for the app

=cut

sub handler {

    ##
    # Fire up jifty
    chdir($ENV{'DOCUMENT_ROOT'});
    Jifty->new() unless (Jifty->handler());

    ##
    # Fix the path to work with CGI
    $ENV{'PATH_INFO'} = $ENV{'REQUEST_URI'};
    my $cgi = new CGI;

    Jifty->handler->handle_request(cgi => $cgi);

    ##
    # Oll Korrect
    return Apache2::Const::OK;
}

1;
