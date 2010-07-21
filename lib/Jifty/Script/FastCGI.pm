use strict;
use warnings;


package Jifty::Script::FastCGI;
use base qw/Jifty::Script/;

use Plack::Handler::FCGI;

=head1 NAME

Jifty::Script::FastCGI - A FastCGI server for your Jifty application

=head1 SYNOPSIS

    AddHandler fastcgi-script fcgi
    FastCgiServer /path/to/your/jifty/app/bin/jifty -initial-env JIFTY_COMMAND=fastcgi 

  Options:
    --maxrequests      maximum number of requests per process

    --help             brief help message
    --man              full documentation

=head1 DESCRIPTION

FastCGI entry point for your Jifty application

=head2 options

=over 8

=item B<--maxrequests>

Set maximum number of requests per process. Read also --man.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut

sub options {
    my $self = shift;
    return (
        $self->SUPER::options,
        'maxrequests=i' => 'maxrequests',
    );
}

=head1 DESCRIPTION

This command is provided for compatibility.  You should probably use
Plack's fastcgi deployment tools with the C<app.psgi> file come with
your jifty app.


When you're ready to move up to something that can handle the increasing load your
new world-changing application is generating, you'll need something a bit heavier-duty
than the pure-perl Jifty standalone server.  C<FastCGI> is what you're looking for.

If you have MaxRequests options under FastCGI in your config.yml, or
commandline option C<--maxrequests=N> assigned, the fastcgi process
will exit after serving N requests.

=head1 SERVER CONFIGURATIONS

=head2 Apache + mod_fastcgi

 # These two lines are FastCGI-specific; skip them to run in vanilla CGI mode
 AddHandler fastcgi-script fcgi
 FastCgiServer /path/to/your/jifty/app/bin/jifty -initial-env JIFTY_COMMAND=fastcgi 

 DocumentRoot /path/to/your/jifty/app/share/web/templates
 ScriptAlias / /path/to/your/jifty/app/bin/jifty/

=head2 Apache + mod_fcgid + mod_rewrite

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

=head2 Lighttpd (L<http://www.lighttpd.net/>)

Version 1.4.23 or newer is recommended, and you may adapt this config:

 server.modules  = ( "mod_fastcgi" )
 server.document-root = "/path/to/your/jifty/app/share/web/templates"
 fastcgi.server = (
        "/" => (
            "your_jifty_app" => (
                "socket"              => "/tmp/your_jifty_app.socket",
                "check-local"         => "disable",
                "fix-root-scriptname" => "enable",
                "bin-path"            => "/path/to/your/jifty/app/bin/jifty",
                "bin-environment"     => ( "JIFTY_COMMAND" => "fastcgi" ),
                "min-procs"           => 1,
                "max-procs"           => 5,
                "max-load-per-proc"   => 1,
                "idle-timeout"        => 20,
            )
        )
    )

Versions before 1.4.23 will work, but you should read L<Plack::Handler::FCGI's lighttpd
documentation|http://search.cpan.org/dist/Plack/lib/Plack/Handler/FCGI.pm#lighttpd>
for how to configure your server.

=head2 More information

Since this uses L<Plack::Handler::FCGI>, you might also want to read
L<its documentation on webserver
configurations|http://search.cpan.org/dist/Plack/lib/Plack/Handler/FCGI.pm#WEB_SERVER_CONFIGURATIONS>.

=head1 METHODS

=head2 run

Creates a new FastCGI process.

=cut

sub run {
    my $self = shift;

    $self->print_help;

    Jifty->new();
    my $conf = Jifty->config->framework('Web')->{'FastCGI'} || {};
    $self->{maxrequests} ||= $conf->{MaxRequests}; # XXX: make it work

    my $server = Plack::Handler::FCGI->new(
        nproc  => $conf->{NProc} || 1,
        detach => 1,
    );

    $server->run(Jifty->handler->psgi_app);
}

1;
