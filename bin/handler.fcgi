#!/usr/bin/perl
package Jifty::Mason;

use strict;
use warnings;
use File::Basename;
use CGI::Fast;
use Module::Refresh;
use HTML::Mason::CGIHandler;


BEGIN {
  my $dir = dirname(__FILE__);
  push @INC, "$dir/../lib";
  push @INC, "$dir/../../Jifty/lib";
}

use Jifty::Everything;


Jifty->new(config_file => $ENV{'Jifty_CONFIG'} ||   dirname(__FILE__).'/../etc/config.yml');
 

our $Handler = HTML::Mason::CGIHandler->new( Jifty::Handler->mason_config );

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

1;
