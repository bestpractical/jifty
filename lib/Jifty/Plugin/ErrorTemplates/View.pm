package Jifty::Plugin::ErrorTemplates::View;

use strict;
use warnings;

use Jifty::View::Declare -base;

use Scalar::Defer;

=head1 NAME

Jifty::Plugin::ErrorTemplates::View - Template pages to show errors

=head1 DESCRIPTION

Default error templates

=cut


template '/error/_elements/error_text' => sub {
    my ($error) = get(qw(error));
    h1 { 'Sorry, something went awry' };
    p  {
        _(
"For one reason or another, you got to a web page that caused a bit of an error. And then you got to our 'basic' error handler. Which means we haven't written a pretty, easy to understand error message for you just yet. The message we do have is:"
        );
    };

    blockquote {
        b { $error || "Internal server error" };
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

This exists as a fallback wrapper, in case the error in question is
caused by the Jifty application's wrapper, for instance.

=cut

{
    no warnings qw'redefine';

    sub wrapper {
        my $code = shift;
        html {
            head {
                title { _('Internal error') } link {
                    attr {
                        rel   => 'stylesheet',
                        type  => 'text/css',
                        href  => "/__jifty/error/error.css",
                        media => 'all'
                    }
                };
            }
            body {
                h1 {'Internal Error'};
                Jifty->web->render_messages;
                $code->();
            }
        }
    }
}


template '__jifty/error/error.css' => sub {
    Jifty->web->response->content_type("text/css");
    h1 {
        outs('color: red');
    };
};

=head2 maybe_page

Like L<Jifty::View::Declare::Helpers/page>, but only outputs a page
wrapper if the request is not a subrequest.

=cut

sub maybe_page (&;$) {
    unshift @_, undef unless @_ == 2;
    my ($meta, $code) = @_;
    my $ret = sub {
        if (Jifty->web->request->is_subrequest) {
            local *is::title = sub {};
            $code->();
        } else {
            page {$meta ? $meta->() : () } content {$code->()};
        }
    };
    $ret->() unless defined wantarray;
    return $ret;
}

template '/errors/404' => sub {
    my $file = get('path') || Jifty->web->request->path;
    Jifty->log->info( "404: user tried to get to " . $file );
    Jifty->web->response->status( 404 )
        unless Jifty->web->request->is_subrequest;
    maybe_page { title => _("Something's not quite right") } content {
        with( id => "overview" ), div {
            p {
                join( " ",
                    _("You got to a page that we don't think exists."),
                    _("Anyway, the software has logged this error."),
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



template '/errors/500' => maybe_page { title => _('Something went awry') } content {
    my $cont = Jifty->web->request->continuation;

    # If we're not in devel, bail
    if ( not Jifty->config->framework("DevelMode") or not $cont ) {
        show("/error/_elements/error_text");
        return;
    }

    my $e = $cont->response->error;
    if ( ref($e) ) {
        my $msg = $e->message;
        $msg =~ s/, <\S+> (line|chunk) \d+\././;

        pre {$msg};

        form {
            form_return( label => _("Try again") );
        };

        h2 {'Call stack'};
        ul {
            for my $frame (@{$e->template_stack}) {
                li { $frame }
            }
        };
    } else {
        pre {$e};
    }
};

1;
