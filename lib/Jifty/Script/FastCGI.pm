use strict;
use warnings;


package Jifty::Script::FastCGI;
use base qw/App::CLI::Command/;

use File::Basename;
use CGI::Fast;
use Module::Refresh;
use HTML::Mason::CGIHandler;
use Jifty::Everything;

=head1 NAME

Jifty::Script::FastCGI - A FastCGI server for your Jifty application

=head1 DESCRIPTION

When you're ready to move up to something that can handle the increasing load your
new world-changing application is generating, you'll need something a bit heavier-duty
than the pure-perl Jifty standalone server.  C<FastCGI> is what you're looking for.

Because Apache's FastCGI dispatcher can't pass commandline flags to your script, you'll need
to call jifty a bit differently:

 AddHandler fastcgi-script fcgi
 DocumentRoot /path/to/your/jifty/app/web/templates
 FastCgiServer /path/to/your/jifty/app/bin/jifty -initial-env JIFTY_COMMAND=fastcgi
 ScriptAlias /  /path/to/your/jifty/app/bin/jifty/




=cut

 
sub run {
    Jifty->new();
    my $Handler = HTML::Mason::CGIHandler->new( Jifty::Handler->mason_config );

    while ( my $cgi = CGI::Fast->new ) {
        # the whole point of fastcgi requires the env to get reset here..
        # So we must squash it again
        $ENV{'PATH'}   = '/bin:/usr/bin';
        $ENV{'CDPATH'} = '' if defined $ENV{'CDPATH'};
        $ENV{'SHELL'}  = '/bin/sh' if defined $ENV{'SHELL'};
        $ENV{'ENV'}    = '' if defined $ENV{'ENV'};
        $ENV{'IFS'}    = '' if defined $ENV{'IFS'};

        Module::Refresh->refresh;


        local $HTML::Mason::Commands::JiftyWeb = Jifty::Web->new();

        if ( ( !$Handler->interp->comp_exists( $cgi->path_info ) )
             && ( $Handler->interp->comp_exists( $cgi->path_info . "/index.html" ) ) ) {
            $cgi->path_info( $cgi->path_info . "/index.html" );
        }

        eval { $Handler->handle_cgi_object($cgi); };
        Jifty::Handler->cleanup_request(); 
    }
}

1;
