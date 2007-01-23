use strict;
use warnings;


package Jifty::Script::FastCGI;
use base qw/App::CLI::Command/;

use File::Basename;
use CGI::Fast;


=head1 NAME

Jifty::Script::FastCGI - A FastCGI server for your Jifty application

=head1 DESCRIPTION

When you're ready to move up to something that can handle the increasing load your
new world-changing application is generating, you'll need something a bit heavier-duty
than the pure-perl Jifty standalone server.  C<FastCGI> is what you're looking for.

Because Apache's FastCGI dispatcher can't pass commandline flags to your script, you'll need
to call jifty a bit differently:

 AddHandler fastcgi-script fcgi
 DocumentRoot /path/to/your/jifty/app/share/web/templates
 FastCgiServer /path/to/your/jifty/app/bin/jifty -initial-env JIFTY_COMMAND=fastcgi
 ScriptAlias /  /path/to/your/jifty/app/bin/jifty/

For B<lighttpd> (L<http://www.lighttpd.net/>), use this setting:

 server.modules  = ( "mod_fastcgi" )
 server.document-root = "/path/to/your/jifty/app/share/web/templates"
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

If you have MaxRequests options under FastCGI in your config.yml, or
commandline option C<--maxrequests=N> assigned, the fastcgi process
will exit after serving N requests. 

An alternative to Apache mod_fastcgi is to use mod_fcgid with mod_rewrite.
If you use mod_fcgid and mod_rewrite, you can use this in your Apache
configuration instead:

 DocumentRoot /path/to/your/jifty/app/share/web/templates
 ScriptAlias /cgi-bin /path/to/your/jifty/app/bin
 DefaultInitEnv JIFTY_COMMAND fastcgi
 <Directory /path/to/your/jifty/app/bin>
     Options ExecCGI
     SetHandler fcgid-script
 </Directory>
 <Directory /path/to/your/jifty/app/share/web/templates>
     RewriteEngine on
     RewriteRule ^$ index.html [QSA]
     RewriteRule ^(.*)$ /cgi-bin/jifty/$1 [QSA,L]
 </Directory>

It may be possible to do this without using mod_rewrite.

=head2 options

=cut

sub options {
    (
        'maxrequests=i' => 'maxrequests',
    );
}

=head2 run

Creates a new FastCGI process.

=cut

sub run {
    my $self = shift;
    Jifty->new();
    my $conf = Jifty->config->framework('Web')->{'FastCGI'} || {};
    $self->{maxrequests} ||= $conf->{MaxRequests};

    my $requests = 0;
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
	if ($self->{maxrequests} && ++$requests >= $self->{maxrequests}) {
	    exit 0;
	}
    }
}

1;
