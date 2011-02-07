package Jifty::View::Declare::Page;
use strict;
use warnings;
use base qw/Template::Declare Class::Accessor::Fast/;

=head1 NAME

Jifty::View::Declare::Page - page wrappers

=head1 DESCRIPTION

This library provides page wrappers

=head1 METHODS

=cut

use Jifty::View::Declare::Helpers;

__PACKAGE__->mk_accessors(qw(content_code done_header _title _meta));
use constant allow_single_page => 1;

=head2 new

Sets up a new page class

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my ($title) = get_current_attr(qw(title));
    $self->_title($title);

    $self->_title($self->_meta->{title})
        if $self->_meta && $self->_meta->{title};

    return $self;
}

=head2 render

Renders everything. This main driver of page rendering and called
right after constructing page object.

=cut

sub render {
    my $self = shift;
    # This needs to be private so we can prepend the header at the end
    Template::Declare->buffer->push(private => 1);
    $self->render_body( sub { $self->render_page->() } );
    $self->render_footer;
    outs_raw(Template::Declare->buffer->pop);
    return '';
}

=head2 render_header $title

Renders an HTML5 "doctype", <head> and the first part of a page body. This bit isn't terribly well thought out and we're not happy with it.

=cut

sub render_header {
    my $self = shift;
    return if $self->done_header;

    Template::Declare->buffer->push( private => 1 );
    outs_raw("<!DOCTYPE html>\n<html>\n");

    $self->_render_header($self->_title || Jifty->config->framework('ApplicationName'));

    $self->done_header(Template::Declare->buffer->pop);
    return '';
};

=head2 render_body $body_code

Renders $body_code inside a body tag

=cut

sub render_body {
    my ($self, $body_code) = @_;

    body {
        Jifty->handler->stash->{'in_body'} = 1;
        $body_code->();
        Jifty->handler->stash->{'in_body'} = 0;
    };
}

=head2 render_page

Renders the skeleton of the page

=cut

sub render_page {
    my $self = shift;

    div {
        div {
            show '/salutation';
            show '/menu';
        };
        div {
            attr { id is 'content' };
            div {
                {
                    no warnings qw( redefine once );

                    local *is::title = $self->mk_title_handler();
                    $self->render_pre_content_hook();
                    Jifty->web->render_messages;

                    $self->content_code->();
                    $self->render_header();

                    $self->render_jifty_page_detritus();
                }

            };
        };
    };
}

=head2 mk_title_handler

Returns a coderef that will make headers for each thing passed to it

=cut

sub mk_title_handler {
    my $self = shift;
    return sub {
        shift;
        for (@_) {
            no warnings qw( uninitialized );
            if ( ref($_) eq 'CODE' ) {
                Template::Declare->buffer->push( private => 1 );
                $_->();
                $self->_title(
                    $self->_title . Template::Declare->buffer->pop );
            } else {
                $self->_title( $self->_title . Jifty->web->escape($_) );
            }
        }
        $self->render_header;
        $self->render_title();
    };
}

=head2 render_title

Renders the in-page title

=cut

sub render_title {
    my $self = shift;
    my $oldt = get('title');
    set( title => $self->_title );
    show '/heading_in_wrapper';
    set( title => $oldt );
}

=head2 render_footer

Renders the page footer and prepends the header to the L<Template::Declare> buffer.

=cut

sub render_footer {
    my $self = shift;
    outs_raw('</html>');
    my $ref = Template::Declare->buffer->buffer_ref;
    $$ref = $self->done_header . $$ref;
    return '';
}

=head2 render_pre_content_hook

Renders the AdminMode alert (if AdminMode is on)

=cut

sub render_pre_content_hook {
    if ( Jifty->admin_mode ) {
        with( class => "warning admin_mode" ), div {
            outs( _('Alert') . ': ' );
            outs_raw(
                Jifty->web->tangent(
                    label => _('Administration mode is enabled.'),
                    url   => '/__jifty/admin/'
                )
            );
            }
    }
}

=head2 render_jifty_page_detritus

Renders the keybinding and PubSub javascript as well as the wait message

=cut

sub render_jifty_page_detritus {
    show('/app_page_footer') if Template::Declare->resolve_template('/app_page_footer' => 1); # the 1 is 'show_private'
    show('/keybindings');
    with( id => "jifty-wait-message", style => "display: none" ),
        div { _('Loading...') };

    # This is required for jifty server push.  If you maintain your own
    # wrapper, make sure you have this as well.
    if ( Jifty->config->framework('PubSub')->{'Enable'} && Jifty::Subs->list )
    {
        script { outs_raw('jQuery(document).ready(function(){new Jifty.Subs({}).start()});') };
    }
}

sub _render_header { 
    my $self = shift;
    my $title = shift || '';
    $title =~ s/<.*?>//g;    # remove html
    HTML::Entities::decode_entities($title);
    my $old = Jifty->handler->stash->{'in_body'};
    Jifty->handler->stash->{'in_body'} = 0;
    with( title => $title ), show('/header');
    Jifty->handler->stash->{'in_body'} = $old;
}

1;
