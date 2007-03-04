package Jifty::Plugin::ErrorTemplates::View;

use strict;
use warnings;
use vars qw( $r );

use Jifty::View::Declare -base;

use Scalar::Defer;

=head1 NAME

Jifty::Plugin::ErrorTemplates::View;

=head1 DESCRIPTION

This class is a stub. It's not in use yet. It should be, but that would require mason libraries to be able to call Template::Declare libraries

=cut


template '__jifty/error/_elements/error_text' => sub {
    my ($error) = get(qw(error));
    h1 { 'Sorry, something went awry' };
    p  {
        _(
"For one reason or another, you got to a web page that caused a bit of an error. And then you got to our 'basic' error handler. Which means we haven't written a pretty, easy to understand error message for you just yet. The message we do have is :"
        );
    };

    blockquote {
        b { $error };
    };

    p {
        _(
"There's a pretty good chance that error message doesn't mean anything to you, but we'd rather you have a little bit of information about what went wrong than nothing. We've logged this error, so we know we need to write something friendly explaining just what happened and how to fix it."
        );
    };

    p {
        hyperlink(
            url   => "/",
            label => _('Head on back home')
        );
        _("for now, and try to forget that we let you down.");
    };
};

=head2 wrapper
                              This exists as a fallback wrapper,
                              in case the error in question is caused by the Jifty app's wrapper, for instance.
=cut

sub wrapper (&) {
    my $code = shift;
    html {
        head {
            title { _('Internal error') }
            link { attr { rel => 'stylesheet', type => 'text/css', href => "/__jifty/error/error.css", media => 'all'}};
        }
        body {
            div { attr { id => 'headers'};
            h1 { 'Internal Error' };
        div { attr { id => 'content'};
                          a { attr { name => 'content'}};
 if (Jifty->config->framework('AdminMode') ) {
     div { attr { class => "warning admin_mode" };
        outs('Alert:' .  tangent( label => 'administration mode' , url => '/__jifty/admin/') .'is enabled.' ) }
 }
 Jifty->web->render_messages;
    $code->();
  }
                              
                          }
                      }}
                  }

template '__jifty/error/dhandler' => sub {
    my $error = get('error');
                            Jifty->log->error( "Unhandled web error " . $error );
                            wrapper {
                              title is 'Something went awry';
                              show('_elements/error_text', error => $error );
                        };
                    };

template '__jifty/error/error.css' => sub {
                            Jifty->handler->apache->content_type("text/css");
                            h1 {
                              outs('color: red');
                              }

                          };


template '/errors/404' => sub {
    my $file = get('path');
    Jifty->log->error( "404: user tried to get to " . $file );
    Jifty->handler->apache->header_out( Status => '404' );
    with( title => _("Something's not quite right") ), wrapper => {

        with( id => "overview" ),
        div {
            p {
                join( " ",
                    _( "You got to a page that we don't think exists." ),
                    _( "Anyway, the software has logged this error." ),
                    _("Sorry about this.") );
                }

                p {
                hyperlink(
                    url   => "/",
                    label => _('Go back home...')
                );
                }

            }
    };
};



template '__jifty/error/mason_internal_error' => page {
    { title is _('Something went awry') }
    my $cont = Jifty->web->request->continuation;
    #my $wrapper = "/__jifty/error/_elements/wrapper" if $cont and $cont->request->path eq "/__jifty/error/mason_internal_error";

    # If we're not in devel, bail
    if ( not Jifty->config->framework("DevelMode") or not $cont ) {
            show("_elements/error_text");
    #    return;
    }

    my $e   = $cont->response->error;
    if (ref($e)) {
    my $msg = $e->message;
    $msg =~ s/, <\S+> (line|chunk) \d+\././;

    my $info  = $e->analyze_error;
    my $file  = $info->{file};
    my @lines = @{ $info->{lines} };
    my @stack = @{ $info->{frames} };

        outs('Error in ');
        _error_line( $file, "@lines" );
        pre {$msg};

        Jifty->web->return( label => _("Try again") );

    h2 { 'Call stack' };
    ul {
        for my $frame (@stack) {
            next if $frame->filename =~ m{/HTML/Mason/};
            li {
                _error_line( $frame->filename, $frame->line );
                }
        }
    }; 
    } else {
    pre {$e};
    }
};

sub _error_line {

    my ( $file, $line ) = (@_);
    if ( -w $file ) {
        my $path = $file;
        for ( map { $_->[1] } @{ Jifty->handler->mason->interp->comp_root } )
        {
            last if $path =~ s/ ^ \Q $_\E //;
        }
        if ( $path ne $file ) {
            outs('template ');
            tangent(
                url        => "/__jifty/edit/mason_component$path",
                label      => "$path line " . $line,
                parameters => { line => $line }
            );
        } else {
            tangent(
                url        => "/__jifty/edit/library$path",
                label      => "$path line " . $line,
                parameters => { line => $line }
            );
        }
    } else {
        outs( '%1 line %2', $file, $line );
    }

}

1;
