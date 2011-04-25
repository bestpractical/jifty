use strict;
use warnings;

package Jifty::Plugin::CompressedCSSandJS;
use base 'Jifty::Plugin';

use IPC::Run3 'run3';
use IO::Handle ();
use Plack::Util;
use HTTP::Message::PSGI;
use HTTP::Request;
use Plack::Response;

=head1 NAME

Jifty::Plugin::CompressedCSSandJS - Compression of CSS and javascript files

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - CompressedCSSandJS:
        js: 1
        css: 1
        jsmin: /path/to/jsmin
        cdn: 'http://yourcdn.for.static.prefix/'
        skipped_js:
            - complex.js
        generate_early: 1


=head1 DESCRIPTION

This plugin provides auto-compilation and on-wire compression of your
application's CSS and Javascript. It is enabled by default, unless
your C<ConfigFileVersion> is greater or equal than 2.

It also supports js minifier, you will need to specify the full path.
The jsmin can be obtained from
L<http://www.crockford.com/javascript/jsmin.html>.

Note that you will need to use C<ConfigFileVersion> 2 to be able to
configure jsmin feature.

skipped_js is a list of js that you don't want to compress for some reason.

generate_early tells the plugin to compress the CSS and JS at process start
rather than on the first request.  This can save time, especially if your
JS minifier is slow, for the poor sucker who makes the first request.  Enabled
by default.

=cut

__PACKAGE__->mk_accessors(qw/css js jsmin cdn skipped_js generate_early/);

=head2 init

Initializes the compression object. Takes a paramhash containing keys
'css' and 'js' which can be used to disable compression on files of
that type.

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt  = @_;
    $self->css( $opt{css} );
    $self->js( $opt{js} );
    $self->jsmin( $opt{jsmin} );
    $self->cdn( $opt{cdn} || '');
    $self->generate_early( exists $opt{generate_early} ? $opt{generate_early} : 1 );

    if ( $self->js_enabled ) {
        Jifty::Web->add_trigger(
            name      => 'include_javascript',
            callback  => sub { $self->_include_javascript(@_) },
            abortable => 1,
        );
        Jifty->add_trigger( post_init => sub { $self->generate_javascript })
            if $self->generate_early;
    }

    if ( $self->css_enabled ) {
        Jifty::Web->add_trigger(
            name => 'include_css',
            callback => sub { $self->_include_css(@_) },
            abortable => 1,
        );
        Jifty->add_trigger( post_init => sub { $self->generate_css })
            if $self->generate_early;
    }
}

=head2 js_enabled

Returns whether JS compression is enabled (which it is by default)

=cut

sub js_enabled {
    my $self = shift;
    defined $self->js ? $self->js : 1;
}

=head2 css_enabled

Returns whether CSS compression is enabled (which it is by default)

=cut

sub css_enabled {
    my $self = shift;
    defined $self->css ? $self->css : 1;
}

sub _include_javascript {
    my $self = shift;

    $self->generate_javascript;
    Jifty->web->out(
        qq[<script type="text/javascript" src="@{[ $self->cdn ]}/__jifty/js/]
          . Jifty::CAS->key( 'ccjs', 'js-all' )
          . qq[.js"></script>] );

    my $skipped_js = $self->skipped_js;
    if ( $self->skipped_js ) {
        for my $file ( @{ $self->skipped_js } ) {
            Jifty->web->out(
                qq{<script type="text/javascript" src="/static/js/$file" /> });
        }
    }
    return 0;
}

sub _include_css {
    my $self = shift;
    $self->generate_css;
    Jifty->web->out(
    qq{<link rel="stylesheet" type="text/css" href="@{[ $self->cdn ]}/__jifty/css/}
    . Jifty::CAS->key('ccjs', 'css-all') . '.css" />');
    return 0;
}

=head3 generate_css 


Checks if the compressed CSS is generated, and if it isn't, generates
and caches it. (In devel mode, it always regenerates it)

=cut

sub generate_css {
    my $self = shift;

    return if Jifty::CAS->key('ccjs', 'css-all') && !Jifty->config->framework('DevelMode');

    $self->log->debug("Generating CSS...");

    my @roots = map { Jifty::Util->absolute_path( $_ ) }
        Jifty->handler->view('Jifty::View::Static::Handler')->roots;

    my $css = CSS::Squish->new( roots => \@roots )->concatenate(
        map { File::Spec->catfile('css', $_ ) } @{ Jifty->web->css_files }
    );

    Jifty::CAS->publish( 'ccjs', 'css-all', $css,
        { content_type => 'text/css', time => time() } );
}



=head3 generate_javascript

Checks if the compressed JS is generated, and if it isn't, generates
and caches it.

=cut

sub generate_javascript {
    my $self = shift;

    return if Jifty::CAS->key('ccjs', 'js-all') && !Jifty->config->framework('DevelMode');

    my $js = $self->_generate_javascript_nocache;

    Jifty::CAS->publish( 'ccjs', 'js-all', $js,
        { content_type => 'application/x-javascript', time => time() } );
}

=head3 _generate_javascript_nocache

Generates compressed javascript, ignoring the cache completely.

=cut

sub _generate_javascript_nocache {
    my $self = shift;
    $self->log->debug("Generating JS...");

    # for the file cascading logic
    my $js = "";

    my $static_app = Jifty->handler->psgi_app_static;

    for my $file ( @{ Jifty::Web->javascript_libs } ) {
        next if $self->_js_is_skipped($file);

        my $res = Plack::Util::run_app
            ( $static_app,
              HTTP::Request->new(GET => "/js/$file")->to_psgi );
        if ($res->[0] == 200) {
            Plack::Util::foreach($res->[2], sub { $js .= $_[0] } );
        }
        else {
            $self->log->error("Unable to include '$file': $res->[0]");
            $js .= "\n/* Unable to include '$file': $res->[0] */\n";
        }
    }

    if ($self->jsmin) {
        eval { $self->minify_js(\$js) };
        $self->log->error("Unable to run jsmin: $@") if $@;
    }

    return $js;
}

=head2 minify_js \$js

Runs the given JS through jsmin

=cut

sub minify_js {
    my $self = shift;
    my $input = shift;
    my ($output, $err);

    $self->log->debug("Minifying JS...");

    # We need to reopen stdout temporarily, because in FCGI
    # environment, stdout is tied to FCGI::Stream, and the child
    # of the run3 wouldn't be able to reopen STDOUT properly.
    my $stdout = IO::Handle->new;
    $stdout->fdopen( 1, 'w' );
    local *STDOUT = $stdout;

    my $stderr = IO::Handle->new;
    $stderr->fdopen( 2, 'w' );
    local *STDERR = $stderr;

    local $SIG{'CHLD'} = 'DEFAULT';
    run3 [$self->jsmin], $input, \$output, \$err;

    my $ret = $? >> 8;
    $self->log->warn("Javascript minify @{[$self->jsmin]} returned $ret:\n$err") if $ret;

    $$input = $output;
}

sub _js_is_skipped {
    my $self       = shift;
    my $file       = shift;
    my $skipped_js = $self->skipped_js;
    return unless $self->skipped_js;
    return grep { $file eq $_ } @{ $self->skipped_js };
}

=head2 wrap

psgi app wrapper to serve url controlled by us

=cut

sub wrap {
    my ($self, $app) = @_;

    sub {
        my $env = shift;
        if (my ($mode, $arg) = $env->{PATH_INFO} =~ m{/__jifty/(css|js)/(.*)}) {
            if ( $arg !~ /^[0-9a-f]{32}\.$mode$/ ) {
                # This doesn't look like a real request for squished JS or CSS,
                # so redirect to a more failsafe place
                my $res = Plack::Response->new;
                $res->redirect( "/static/$mode/$arg" );
                return $res->finalize;
            }

            my $method = "generate_".($mode eq 'js' ? 'javascript' : 'css');
            $self->can($method)->($self);
            $arg =~ s/\.$mode//;
            return Jifty::CAS->serve_by_name( 'ccjs', $mode.'-all', $arg, $env );
        }
        else {
            return $app->($env);
        }
    };
}


1;
