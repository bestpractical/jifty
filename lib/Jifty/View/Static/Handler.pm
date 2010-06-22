use warnings;
use strict;
use File::MMagic ();
use MIME::Types ();
use HTTP::Date ();

package Jifty::View::Static::Handler;

use base qw/Jifty::View/;

our ($MIME,$MAGIC);

=head1 NAME

Jifty::View::Static::Handler - Jifty view handler for static files

=head1 DESCRIPTION

This is deprecated and is being port to a stack of plack middleware and plack::app::file

This class takes care of serving out static files for a Jifty application. 

When fully operational, it will use an algorithm along the lines of the following:

* Static files are served out of a separate root
* If static files go through apache:
    * How do we merge together the N static roots?
* If static files go through Jifty::Handler
    * We need a flag to allow them to go through the dispatcher, too
    * return "True" (304) for if-modified-since
    * if the browser accepts gzipped data,
        see if we have a cached gzipped copy
            if so, send it
        see if we have a marker indicating that gzip is a lose
            if so, send uncompressed

        gzip the content
        send the gzipped content
     * if the browser doesn't accept gzipped content
        send the content uncompressed

=head2 new

Create a new static file handler. Likely, only the C<Jifty::Handler> needs to do this.

=cut

sub new {
    my $class = shift;
    my @roots = (Jifty->config->framework('Web')->{StaticRoot});
    my %seen; $seen{$_} = 1 for map Jifty->config->framework('Web')->{$_}, qw/StaticRoot DefaultStaticRoot/;
    for my $plugin ( Jifty->plugins ) {
        for my $root ($plugin->static_root) {
            next unless ( defined $root and -d $root and -r $root and not $seen{$root}++);
            push @roots, $root;
            $plugin->log->debug( "Plugin @{[ref($plugin)]} static root added: (@{[$root ||'']})");
        }
    }
    push @roots, (Jifty->config->framework('Web')->{DefaultStaticRoot});

    return bless { roots => \@roots }, $class;
}

=head2 roots

Returns all the static roots the handler will search

=cut

sub roots {
    my $self = shift;
    return wantarray ? @{$self->{roots}} : $self->{roots};
}

=head2 show $path

Handle a request for C<$path>. If we can't find a static file of that name, return undef.

=head2 handle_request $path

An alias for L</show>

=cut


sub show {
    shift->handle_request(@_);
}

sub handle_request {
    my $self = shift;
    my $path = shift;

    my $local_path = $self->file_path($path) or return undef;

    if ( my $since = Jifty->web->request->header('If-Modified-Since') ) {
        my @file_info = stat($local_path);

        # IE appends "; length=N" to If-Modified-Since headers and we need
        # to get rid of it so str2time doesn't choke below
        $since =~ s/;.+$//;

        return $self->send_not_modified
            unless $file_info[9] > HTTP::Date::str2time($since);
    }

    return $self->send_file($local_path, $self->mime_type($local_path));

}


=head2 file_path $path

Returns the system path for C<$path>, searching inside the
application's static root, loaded plugins' static roots, and finally
Jifty's static root.  Returns undef if it can't find the file in any
path.

=cut

=head2 template_exists $path

An alias for L</file_path>.

=cut

sub template_exists {
    my $class = shift;
    my $template = shift;
    return $template if $class->file_path($template);
    return undef;
}

sub file_path {
    my $self    = shift;
    my $file    = shift;

    # Chomp a leading "/static" - should this be configurable?
    $file =~ s/^\/*?static//; 

    foreach my $path ( $self->roots ) {
        my $abspath = Jifty::Util->absolute_path( File::Spec->catdir($path,$file ));
        # If the user is trying to request something outside our static root, 
        # decline the request
        my $abs_base_path = Jifty::Util->absolute_path( $path );
        unless ($abspath =~ /^\Q$abs_base_path\E/) {
            return undef;
        }
        return $abspath if ( -f $abspath && -r $abspath );
    }
    return undef;

}

=head2 mime_type $path

Returns the mime type of the file whose path on disk is C<$path>. Tries to use
L<MIME::Types> to guess first. If that fails, it falls back to C<File::MMagic>.

=cut

sub mime_type {
    my $self       = shift;
    my $local_path = shift;

    # The key is the file extension, the value is the MIME type to send.
    my %type_override = (
        'json' => 'application/json; charset=UTF-8',
        'htc'  => 'text/x-component',
    );

    return ($type_override{$1})
        if $local_path =~ /^.*\.(.+?)$/ and defined $type_override{$1};

    # Defer initialization to first use. (It's not actually cheap)
    $MIME ||= MIME::Types->new();
    $MAGIC ||= File::MMagic->new();
    my $mimeobj   = $MIME->mimeTypeOf($local_path);
    my $mime_type = ( $mimeobj ? $mimeobj->type : $MAGIC->checktype_filename($local_path));

    return ($mime_type);
}


=head2 send_file $path $mimetype

Print C<$path> to STDOUT (the client), identified with a mimetype of C<$mimetype>.

=cut


sub send_file {
    my $self        = shift;
    my $local_path  = shift;
    my $mime_type   = shift;

    my $fh = IO::File->new( $local_path, 'r' );
    if ( defined $fh ) {
        binmode $fh;

        # This is designed to work under CGI or FastCGI; will need an
        # abstraction for mod_perl

        # Clear out the mason output, if any
        Jifty->web->mason->clear_buffer if Jifty->web->mason;

        my @file_info = stat($local_path);
        Jifty->web->response->content_type($mime_type);
        $self->send_http_header( '', $file_info[7], $file_info[9] );

        Jifty->web->response->content($fh);

        return 1;
    }
    else {
        return undef;
    }
}

=head2 send_http_header [COMPRESSION, LENGTH, LAST_MODIFIED]

Sends appropriate cache control and expiration headers such that the
client will cache the content.  COMPRESSION is deprecated

=cut

sub send_http_header {
    my $self = shift;
    my (undef, $length, $modified) = @_;
    my $now    = time();
    my $response = Jifty->web->response;

    # Expire in a year
    $response->header( 'Cache-Control' => 'max-age=31536000, public' );
    $response->header( 'Expires' => HTTP::Date::time2str( $now + 31536000 ) );
    $response->header( 'Content-Length' => $length ) if $length;

    $response->header(
      'Last-Modified' => HTTP::Date::time2str( $modified ) ) if $modified;
}


=head2 send_not_modified

Sends a "304 Not modified" response to the browser, telling it to use a cached copy.

=cut

sub send_not_modified {
    my $self = shift;
    my $response = Jifty->web->response;
    $response->status( 304 );
    return 1;
}

1;
