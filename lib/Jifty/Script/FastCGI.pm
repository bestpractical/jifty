use strict;
use warnings;


package Jifty::Script::FastCGI;
use base qw/App::CLI::Command/;

use File::Basename;
use CGI::Fast;
use Module::Refresh;
use HTML::Mason::CGIHandler;
use Jifty::Everything;


 
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


        $HTML::Mason::Commands::framework = Jifty::Web->new();

        if ( ( !$Handler->interp->comp_exists( $cgi->path_info ) )
             && ( $Handler->interp->comp_exists( $cgi->path_info . "/index.html" ) ) ) {
            $cgi->path_info( $cgi->path_info . "/index.html" );
        }

        eval { $Handler->handle_cgi_object($cgi); };
        Jifty::Handler->cleanup_request(); 
        $HTML::Mason::Commands::framework = undef;
        # Cleanup and inhibit warnings
    }
}

1;
