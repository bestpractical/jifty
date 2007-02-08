use warnings;
use strict;
package Jifty::View::Declare::Helpers;

use base qw/Exporter/;
use Template::Declare::Tags;

use base qw/Template::Declare/;
our @EXPORT = (qw(form hyperlink tangent redirect new_action form_submit form_next_page page wrapper request get set render_param current_user render_action render_region ), @Template::Declare::Tags::EXPORT);

{
no warnings qw/redefine/;
sub form (&){
    my $code = shift;
    outs_raw(Jifty->web->form->start);
    $code->();
    outs_raw(Jifty->web->form->end);
    return ''
}
}

sub hyperlink(@) {
    outs_raw(Jifty->web->link(@_));
    return '';
}

sub tangent(@) {
    outs_raw(Jifty->web->tangent(@_));
    return '';
}
sub redirect(@) {
    Jifty->web->redirect(@_);
    return ''
}

sub new_action(@){
    return Jifty->web->new_action(@_);
}

sub render_region(@){
    unshift @_, 'name' if @_ % 2;
    Template::Declare->new_buffer_frame;
    Jifty::Web::PageRegion->new(@_)->render;
    my $content = Template::Declare->buffer->data();
    Template::Declare->end_buffer_frame;
    Jifty->web->out($content);
}

sub render_action(@){
    my ($action, $fields, $field_args) = @_;
    my @f = $fields && @$fields ? @$fields : $action->argument_names;
    foreach my $argument (@f) {
        outs_raw($action->form_field($argument, %$field_args));
    }
}

sub form_submit(@){
    outs_raw( Jifty->web->form->submit(@_));
    '';
}

sub form_next_page(@){
    Jifty->web->form->next_page(@_);
}

sub request {
    Jifty->web->request;
}

sub current_user {
    Jifty->web->current_user;
}

sub get {
    if (wantarray) {
        map { request->argument($_) }  @_;
    }
    else {
        request->argument($_[0]);
    }
}

sub set {
    while (my ($arg, $val) = (shift @_, shift @_)){ 
    request->argument($arg => $val);
    }

}


sub render_param {
    my $action = shift;
    outs_raw($action->form_field(@_));
    return '';
}

# template 'foo' => page {{ title is 'Foo' } ... };
sub page (&) {
    my $code = shift;
    sub {
        Jifty->handler->apache->content_type('text/html; charset=utf-8');
        show('/_elements/nav');
        wrapper($code);
    };
}


sub wrapper ($) {
    my $content_code = shift;

    my ($title) = get_current_attr(qw(title));

    my $done_header;
    my $render_header = sub {
        no warnings qw( uninitialized redefine once );

        defined $title or return;
        return if $done_header++;

        Template::Declare->new_buffer_frame;
        render_header($title);
        $done_header = Template::Declare->buffer->data;
        Template::Declare->end_buffer_frame;


        '';
    };

    body {
        show('/_elements/sidebar');
        with( id => "content" ), div {
            with( name => 'content' ), a {};
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
            Jifty->web->render_messages;

            {
                no warnings qw( uninitialized redefine once );

                local *is::title = sub {
                    shift;
                    $title = "@_";
                    &$render_header;
                };

                &$content_code;
                if ( !$done_header ) {
                    $title = _("Untitled");
                    &$render_header;
                }
            }

            show('/_elements/keybindings');
            with( id => "jifty-wait-message", style => "display: none" ),
              div { _('Loading...') };

# Jifty::Mason::Halo->render_component_tree if ( Jifty->config->framework('DevelMode') );

            # This is required for jifty server push.  If you maintain your own
            # wrapper, make sure you have this as well.
            if (   Jifty->config->framework('PubSub')->{'Enable'}
                && Jifty::Subs->list )
            {
                script { outs('new Jifty.Subs({}).start();') };
            }
        };
    };

        Template::Declare->buffer->data( $done_header . Template::Declare->buffer->data);
}

sub render_header {
    my ($title) = @_;
    outs_raw('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
            . '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">' );
    with( title => $title ), show('/_elements/header');
    div {
        { id is 'headers' }
        hyperlink(
            url   => "/",
            label => _( Jifty->config->framework('ApplicationName') )
        );
        with( class => "title" ), h1 { $title };
    };
}


1;
