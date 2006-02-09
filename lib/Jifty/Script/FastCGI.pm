use strict;
use warnings;


package Jifty::Script::FastCGI;
use base qw/App::CLI::Command/;

use File::Basename;
use CGI::Fast;
use Module::Refresh;
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

For B<lighttpd> (L<http://www.lighttpd.net/>), use this setting:

 server.modules  = ( "mod_fastcgi" )
 server.document-root = "/path/to/your/jifty/app/web/templates"
 fastcgi.server = (
        "" => (
            "your_jifty_app" => (
                "socket"       => "/tmp/your_jifty_app.socket",
                "check-local"  => "disable",
                "bin-path"     => "/path/to/your/jifty/app/bin/jifty",
                "bin-environment" => ( "JIFTY_COMMAND" => "fastcgi" ),
                "min-procs"    => 1,
                "max-procs"    => 5,
                "max-load-per-proc" => 1,
                "idle-timeout" => 20,
            )
        )
    )

=head2 run

Creates a new FastCGI process.

=cut
 
sub run {
    Jifty->new();

    use Hook::LexWrap;
    wrap 'HTML::Mason::FakeApache::send_http_header', pre => sub {
        my $r = shift;
        $r->header_out( @{$_} ) for Jifty->web->response->headers;
    };

    while ( my $cgi = CGI::Fast->new ) {
        # the whole point of fastcgi requires the env to get reset here..
        # So we must squash it again
        $ENV{'PATH'}   = '/bin:/usr/bin';
        $ENV{'SHELL'}  = '/bin/sh' if defined $ENV{'SHELL'};
        $ENV{'PATH_INFO'}   = $ENV{'SCRIPT_NAME'}
            if $ENV{'SERVER_SOFTWARE'} =~ /^lighttpd\b/;
        for (qw(CDPATH ENV IFS)) {
            $ENV{$_} = '' if (defined $ENV{$_} );
        }
        Jifty->handler->handle_request( cgi => $cgi );
    }
}

1;
