use strict;
use warnings;

package Jifty::Plugin::CompressedCSSandJS;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

use Digest::MD5 qw(md5_hex);
use IPC::Run3 'run3';
use IO::Handle ();

=head1 NAME

Jifty::Plugin::CompressedCSSandJS

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - CompressedCSSandJS:
        js: 1
        css: 1
        jsmin: /path/to/jsmin

=head1 DESCRIPTION

This plugin provides auto-compilation and on-wire compression of your
application's CSS and Javascript. It is enabled by default, unless
your C<ConfigFileVersion> is greater or equal than 2.

It also supports js minifier, you will need to specify the full path.
The jsmin can be obtained from
L<http://www.crockford.com/javascript/jsmin.html>.

Note that you will need to use C<ConfigFileVersion> 2 to be able to
configure jsmin feature.

=cut

__PACKAGE__->mk_accessors(qw(css js jsmin cached_javascript cached_javascript_digest cached_javascript_time ));

=head2 init

Initializes the compression object. Takes a paramhash containing keys
'css' and 'js' which can be used to disable compression on files of
that type.

=cut

sub init {
    my $self = shift;
    my %opt  = @_;
    $self->css( $opt{css} );
    $self->js( $opt{js} );
    $self->jsmin( $opt{jsmin} );

    Jifty::Web->add_trigger(
        name      => 'include_javascript',
        callback  => sub { $self->_include_javascript(@_) },
        abortable => 1,
    ) if $self->js_enabled;
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

    $self->_generate_javascript;
    Jifty->web->out( qq[<script type="text/javascript" src="/__jifty/js/]
            . $self->cached_javascript_digest
            . qq[.js"></script>] );
    return 0;
}

=head3 _generate_javascript

Checks if the compressed JS is generated, and if it isn't, generates
and caches it.

=cut

sub _generate_javascript {
    my $self = shift;

    if ( not defined $self->cached_javascript_digest
        or Jifty->config->framework('DevelMode') ) {
        Jifty->log->debug("Generating JS...");

        my @roots = (
            Jifty::Util->absolute_path(
                File::Spec->catdir(
                    Jifty->config->framework('Web')->{'StaticRoot'}, 'js'
                )
            ),

            Jifty::Util->absolute_path(
                File::Spec->catdir(
                    Jifty->config->framework('Web')->{'DefaultStaticRoot'},
                    'js'
                )
            ),
        );

        my $js = "";

        for my $file ( @{ Jifty::Web->javascript_libs } ) {
            my $include;

            for my $root (@roots) {
                my @spec = File::Spec->splitpath( $root, 1 );
                my $path = File::Spec->catpath( @spec[ 0, 1 ], $file );

                if ( -e $path ) {
                    $include = $path;
                    last;
                }
            }

            if ( defined $include ) {
                my $fh;

                if ( open $fh, '<', $include ) {
                    $js .= "/* Including '$file' */\n\n";
                    $js .= $_ while <$fh>;
                    $js .= "\n/* End of '$file' */\n\n";
                } else {
                    $js .= "\n/* Unable to open '$file': $! */\n";
                }
            } else {
                $js .= "\n/* Unable to find '$file' */\n";
            }
        }
        if ($self->jsmin) {
            eval { $self->minify_js(\$js) };
            Jifty->log->error("Unable to run jsmin: $@") if $@;
        }
        $self->cached_javascript($js);
        $self->cached_javascript_digest( md5_hex($js) );
        $self->cached_javascript_time(time);
    }
}

=head2 minify_js \$js

Runs the given JS through jsmin

=cut

sub minify_js {
    my $self = shift;
    my $input = shift;
    my $output;

    Jifty->log->debug("Minifying JS...");

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
    run3 [$self->jsmin], $input, \$output, undef;

    $$input = $output;
}

1;
