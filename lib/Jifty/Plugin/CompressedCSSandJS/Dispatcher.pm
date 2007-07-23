use warnings;
use strict;

package Jifty::Plugin::CompressedCSSandJS::Dispatcher;

=head1 NAME

Jifty::Plugin::CompressedCSSandJS::Dispatcher

=head1 DESCRIPTION

Adds dispatcher rules for C</__jifty/js/*> and C</__jifty/css/*/>,
which serve out compiled and compressed CSS and Javascript rules.

=cut
use Compress::Zlib qw();
use HTTP::Date ();

use Jifty::Dispatcher -base;

on '/__jifty/js/*' => run {
    my $arg = $1;
    if ( $arg !~ /^[0-9a-f]{32}\.js$/ ) {

        # This doesn't look like a real request for squished JS,
        # so redirect to a more failsafe place
        Jifty->web->redirect( "/static/js/" . $arg );
    }

    my ($ccjs) = Jifty->find_plugin('Jifty::Plugin::CompressedCSSandJS')
        or Jifty->web->redirect( "/static/js/" . $arg );

    $ccjs->_generate_javascript;

    if ( Jifty->handler->cgi->http('If-Modified-Since')
        and $arg eq $ccjs->cached_javascript_digest . '.js' )
    {
        Jifty->log->debug("Returning 304 for cached javascript");
        Jifty->handler->apache->header_out( Status => 304 );
        Jifty->handler->apache->send_http_header();
        return;
    }

    Jifty->handler->apache->content_type("application/x-javascript");
    Jifty->handler->apache->header_out( 'Expires' => HTTP::Date::time2str( time + 31536000 ) );

    # XXX TODO: If we start caching the squished JS in a file somewhere, we
    # can have the static handler serve it, which would take care of gzipping
    # for us.
    if ( Jifty::View::Static::Handler->client_accepts_gzipped_content ) {
        Jifty->log->debug("Sending gzipped squished JS");
        Jifty->handler->apache->header_out( "Content-Encoding" => "gzip" );
        Jifty->handler->apache->send_http_header();
        binmode STDOUT;
        print Compress::Zlib::memGzip( $ccjs->cached_javascript );
    } else {
        Jifty->log->debug("Sending squished JS");
        Jifty->handler->apache->send_http_header();
        print $ccjs->cached_javascript;
    }
    abort;
};

on '/__jifty/css/*' => run {
    my $arg = $1;
    if ( $arg !~ /^[0-9a-f]{32}\.css$/ ) {

        # This doesn't look like a real request for squished CSS,
        # so redirect to a more failsafe place
        Jifty->web->redirect( "/static/css/" . $arg );
    }

    Jifty->web->generate_css;

    if ( Jifty->handler->cgi->http('If-Modified-Since')
        and $arg eq Jifty->web->cached_css_digest . '.css' )
    {
        Jifty->log->debug("Returning 304 for cached css");
        Jifty->handler->apache->header_out( Status => 304 );
        return;
    }

    Jifty->handler->apache->content_type("text/css");
    Jifty->handler->apache->header_out( 'Expires' => HTTP::Date::time2str( time + 31536000 ) );

    # XXX TODO: If we start caching the squished CSS in a file somewhere, we
    # can have the static handler serve it, which would take care of gzipping
    # for us.
    if ( Jifty::View::Static::Handler->client_accepts_gzipped_content ) {
        Jifty->log->debug("Sending gzipped squished CSS");
        Jifty->handler->apache->header_out( "Content-Encoding" => "gzip" );
        Jifty->handler->apache->send_http_header();
        binmode STDOUT;
        print Compress::Zlib::memGzip( Jifty->web->cached_css );
    } else {
        Jifty->log->debug("Sending squished CSS");
        Jifty->handler->apache->send_http_header();
        print Jifty->web->cached_css;
    }
    abort;
};

1;
