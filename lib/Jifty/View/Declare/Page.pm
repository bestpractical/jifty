package Jifty::View::Declare::Page;
use strict;
use warnings;
use base qw/Template::Declare Class::Accessor::Fast/;
use Template::Declare::Tags;

=head1 NAME

Jifty::View::Declare::Page

=head1 DESCRIPTION

This library provides page wrappers

=head1 METHODS

=cut

use Jifty::View::Declare::Helpers;

__PACKAGE__->mk_accessors(qw(content_code done_header _title));
use constant allow_single_page => 1;

=head2 new

Sets up a new page class

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my ($title) = get_current_attr(qw(title));
    $self->_title($title);

    return $self;
}

=head2 render_header $title

Renders an HTML "doctype", <head> and the first part of a page body. This bit isn't terribly well thought out and we're not happy with it.

=cut

sub render_header {
    my $self = shift;
    return if $self->done_header;

    Template::Declare->new_buffer_frame;
    outs_raw(
        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' . "\n"
      . '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">' . "\n" );

    $self->_render_header($self->_title || Jifty->config->framework('ApplicationName'));

    $self->done_header(Template::Declare->buffer->data);
    Template::Declare->end_buffer_frame;
    return '';
};

=head2 render_body $body_code

Renders $body_code inside a body tag

=cut

sub render_body {
    my ($self, $body_code) = @_;

    body { $body_code->() };
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
                Template::Declare->new_buffer_frame;
                $_->();
                $self->_title(
                    $self->_title . Template::Declare->buffer->data );
                Template::Declare->end_buffer_frame;
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
    Template::Declare->buffer->data( $self->done_header . Template::Declare->buffer->data );
}

=head2 render_pre_content_hook

Renders the AdminMode alert (if AdminMode is on)

=cut

sub render_pre_content_hook {
    if ( Jifty->config->framework('AdminMode') ) {
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

    show('/keybindings');
    with( id => "jifty-wait-message", style => "display: none" ),
        div { _('Loading...') };

    # This is required for jifty server push.  If you maintain your own
    # wrapper, make sure you have this as well.
    if ( Jifty->config->framework('PubSub')->{'Enable'} && Jifty::Subs->list )
    {
        script { outs('new Jifty.Subs({}).start();') };
    }
}

sub _render_header { 
    my $self = shift;
    my $title = shift || '';
    $title =~ s/<.*?>//g;    # remove html
    HTML::Entities::decode_entities($title);
    with( title => $title ), show('/header');
}

1;
