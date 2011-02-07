package Jifty::Plugin::ViewDeclarePage::Page;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::View::Declare::Page::NewStyle - new style page wrapper to simplify customization and reuse.

=head1 DESCRIPTION

This library is a replacement for L<Jifty::View::Declare::Page>.
That is in Jifty for a while and can not be replaced with something
completely different because of backwards compatibility.

When you declare a L<Jifty::View::Declare> template that is a page, for example:

    template 'news' => page {
        ...
    };

Page classes come into game. First of all App::View::Page is loaded
(it's not true and there is a way to define class for particular page,
but lets leave it alone as interface is not settled enough to be
discussed). If the app class doesn't exist then default
L<Jifty::View::Declare::Page> is used. Code block right after page
token is used to render core of the page wrapped into some layout.
Page classes implement such layouts.

It's very hard to extended L<Jifty::View::Declare::Page> class as
it's written in such a way that forces you to copy&paste some
internals from the class to make overriden method work and don't
break things.

I think this implementation is much better thing. To use this class
as a base for all your pages you can just add this plugin to your app
and simple YourApp::View::Page will be generated for you. However,
if you're here then you want to change layout, your App::View::Page
should be something like:

    package MyApp::View::Page;
    use base qw(Jifty::Plugin::ViewDeclarePage::Page);
    use Jifty::View::Declare::Helpers;

    ...

    1;

=head1 DIFFERENCES FROM DEFAULT PAGE CLASS

=over 4

=item no calls into templates

Yes, that's it. No call to show('/menu'), instead it's a method
L</render_navigation> here. Why? If it's subclassable then there is no
need to split functionality between different modules. You
can always return old behavior by using:

    sub render_navigation { show(/menu) }

=item no render_pre_content_hook

override L</render_content>.

=item title is always rendered in page

Even when there is no 'page_title is ...' in the content code,
see L</instrument_content> and L</render_title_inpage>.

=item no html in title

All HTML is just escaped. 99% of apps don't want to put tags inside
title. Sure, it's wrapped into <h1> tag. See L</render_title_inpage>

=item new 'add rel ...' and 'add rev ...'

Can be used in the content code to define feeds, relative links and other
cool stuff. See L</instrument_content> and L</render_link_inpage>.

=item at last

It's documented!

=back

=cut


__PACKAGE__->mk_accessors(qw(content_code _title _links _meta));
use constant allow_single_page => 1;

=head1 ACCESSORS

=over 4

=item content_code

Code reference that renders the core of the page, this is code block
right after page token in the following example:

    template 'news' => page {
        ...
    };

Is set by jifty during construction of the page object.

=item _meta

A hash reference that is set by jifty during construction of
the page object. It's empty unless you use the following syntax:

    template my_page => page { some => 'value', ... } content {
        ...
    };

In this case _meta is a reference to the hash that goes right after
page token and content_code is after content token.

=item _title and _links

These are internal temporary holders of corresponding data.

=back

=head1 METHODS

=head2 Initialization and rendering driver

=head3 new

Sets up a new page class. Called by Jifty with content_code and
optional _meta.

Calls L</init> right before returning new instance of the class.

=cut

sub new {
    my $class = shift;
    my $props = shift;
    $props->{'_meta'} ||= {};
    $props->{'_links'} ||= [];
    my $self = $class->SUPER::new($props);
    $self->init;
    return $self;
}

=head3 init

Sets _title accessor from 'title' in _meta if the latter is defined,
so you can do the following if title of a page is static:

    template news => page { title => _('News') } content {
        ...
    };

=cut

sub init {
    my $self = shift;

    if ( defined (my $title = $self->_meta->{'title'}) ) {
        $self->_title( $title );
    }

    return $self;
}

=head3 render

Renders whole page from doctype till closing html tag. Takes
no arguments.

This method drives rendering of the page. Page is split
into three major parts: header, body and footer. Each is
implemented as corresponding method with 'render_' prefix.

It worth to note that order of rendering is changed and
header is rendered after the body to allow you define page
title, RSS feeds and other things in content. Read more
about this below in L</render_header> and L</instrument_content>.

=cut

sub render {
    my $self = shift;

    Template::Declare->buffer->push( private => 1 );
    $self->render_body;
    my $body = Template::Declare->buffer->pop;

    $self->render_header;

    Template::Declare->buffer->append( $body );

    $self->render_footer;
}

=head2 Main blocks of the page

=head3 render_header

Renders an HTML "doctype" and complete <head> tag. Usually you don't
want to override this. This method is rendered after body and main
content of the page, so all things you need in head tag you can define
in content.

=over 4

=item doctype

Calls L</render_doctype>.

=item C<page_title is ...>

You can define dynamic title using the following:

    template some => page {
        my $page_title = ...;
        ...
        page_title is $page_title;
        ...
    };

Don't want to define dynamic title then as well you can use syntax
described in L</init> above.

When 'page_title is' is used in the content code, L</render_title_inpage>
is called, read more in L</instrument_content>.

L</render_title_inhead> is called during rendering of the head tag,
so you can change title there as well by subclassing that method.

=item tag <link>, C<add rel ...> and C<add rev ...>

You can add <link> tags right from the content using the following syntax:

    add rel "alternate",
        type => "application/atom+xml",
        title => _('Updated this week'),
        href => '/feeds/atom/recent',
    ;

When these constructions are used, L</render_link_inpage> is called
so you can add something right in the page content, for example
RSS image with link to the feed. See also L</instrument_content>.

L</render_links_inhead> is called during rendering of the head tag.

=item css and js

Links to CSS and JS files are rendered for you using
L<Jifty::Web/include_css> and L<Jifty::Web/include_js> functions.

Read docs around those methods and L<Jifty::Manual> on adding your
own styles and scripts.

=item meta

Not implemented, but will be as soon as syntax will be defined.

=back

=cut

sub render_header {
    my $self = shift;

    $self->render_doctype;

    head {
        Jifty->web->response->content_type('text/html; charset=utf-8');
        with(
            'http-equiv' => "content-type",
            content      => "text/html; charset=utf-8"
        ), meta {};
        $self->render_title_inhead( $self->_title );
        $self->render_links_inhead( @{ $self->_links || [] } );
        Jifty->web->include_css;
        Jifty->web->include_javascript;
    };
    return '';
};

=head3 render_body

Renders body tag, declares that we're in body and calls L</render_page>
that actually defines layout of the body. L</render_page> method is better
target for subclassing instead of this.

=cut

sub render_body {
    my $self = shift;
    body {
        Jifty->handler->stash->{'in_body'} = 1;
        $self->render_page;
        Jifty->handler->stash->{'in_body'} = 0;
    };
    return '';
}

=head3 render_footer

Renders the page footer - </html> tag :)

=cut

sub render_footer {
    my $self = shift;
    outs_raw('</html>');
    return '';
}

=head2 Body layout

=head3 render_page

Renders the skeleton of the page and then calls L</instrument_content>
to prepare and finally render L</content_code> using L</render_content>.

Default layout of the page is the following:

    <div>
      <div>
        this->render_salutation
        this->render_navigation
      </div>
      <div id="content"><div>
        this->instrument_content
        this->render_jifty_page_detritus
      </div></div>
    </div>

=cut

sub render_page {
    my $self = shift;
    div {
        div {
            $self->render_salutation;
            $self->render_navigation;
        }
        div { attr { id is 'content' };
            div {
                $self->instrument_content;
                $self->render_jifty_page_detritus;
            }
        }
    };
    return '';
}

=head3 instrument_content

Something you don't want ever touch. However, does the following:

=over 4

=item setups local 'page_title is ...' handler which calls L</render_title_inpage>
if 'page_title is' is used.

=item if 'page_title is' is not used then calls L</render_title_inpage> after
and put result into output stream before the content.

=item setup handler for 'add rel ...' and 'add rev ...', that calls
L</render_link_inpage> and fills _links accessor.

=item sure calls L</render_content>.

=back

=cut

sub instrument_content {
    my $self = shift;

    no warnings qw( redefine once );

    my $seen_title = 0;
    local *is::page_title = sub {
        shift;
        $seen_title = 1;
        no warnings qw(uninitialized);
        my $res = '';
        for (@_) {
            # just in case somebody if somebody put a tag into title
            # tags' code may play with buffers directly
            if ( ref($_) eq 'CODE' ) {
                Template::Declare->buffer->push( private => 1);
                $_->();
                $res .= Template::Declare->buffer->pop;
            } else {
                $res .= $_;
            }
        }
        $self->_title( $self->_title . $res );
        $self->render_title_inpage( $self->_title );
        return '';
    };

    local *rel::add = sub {
        shift;
        my %args = ('rel', @_);
        my $links = $self->_links;
        push @$links, \%args;
        $self->_links( $links );
        $self->render_link_inpage( %args );
        return '';
    };

    local *rev::add = sub {
        shift;
        my %args = ('rev', @_);
        my $links = $self->_links;
        push @$links, \%args;
        $self->_links( $links );
        $self->render_link_inpage( %args );
        return '';
    };

    Template::Declare->buffer->push( private => 1 );
    $self->render_content;
    my $content = Template::Declare->buffer->pop;

    unless ( $seen_title ) {
        $self->render_title_inpage( $self->_title );
    }

    Template::Declare->buffer->append( $content );
    return '';
}

=head3 render_content

Renders content of the page - L</content_code>.

=cut

sub render_content {
    my $self = shift;

    $self->content_code->();

    return '';
}

=head2 Helpers

=head3 render_doctype

Renders default doctype (HTML5) and opening C<< <html> >> tag

=cut

sub render_doctype {
    outs_raw("<!DOCTYPE html>\n<html>\n");
    return '';
}

=head3 render_title_inhead

Should output nothing but a title tag what will be placed into the head.
Title is passed as only argument. Arguments are combined.

=cut

sub render_title_inhead {
    my $self = shift;
    my $title = shift
        || Jifty->config->framework('ApplicationName');

    title { $title };
    return '';
}

=head3 render_title_inpage

Renders the in-page title, followed by L<page navigation|Jifty::Web/page_navigation>
and L<jifty messages|Jifty::Web/render_messages>.

See L</render_title_inhead>, L</instrument_content> and L</render_header>.

=cut

sub render_title_inpage {
    my $self = shift;
    my $title = shift;

    if ( $title ) {
        h1 { attr { class => 'title' }; outs($title) };
    }

    Jifty->web->page_navigation->render_as_menu;

    Jifty->web->render_messages;

    return '';
}

=head3 render_links_inhead

Renders link tags which are passed as list of hashes.

=cut

sub render_links_inhead {
    my $self = shift;
    my @links = @_;
    foreach ( @links ) {
        with ( %$_ ), link { };
    }
    return '';
}

=head3 render_link_inpage

Do nothing by default, but link as a hash is passed
when content has 'add rel ...' or 'add rev ...'.

Read more in L</render_header> and L</instrument_content>.

=cut

sub render_link_inpage { return '' }

=head3 render_navigation

Renders L<Jifty::Web/navigation> as L<menu|Jifty::Web::Menu/render_as_menu>
wrapped into a div with id 'navigation'. There is as well page_navigation
in Jifty that is rendered in L</render_title_inpage> by default.

Called from L</render_page>.

=cut

sub render_navigation {
    my $self = shift;
    my @args = @_;
    div { attr { id => "navigation" };
        Jifty->web->navigation->render_as_menu(@args);
    };
    return '';
}

=head3 render_salutation

Renders salutation for the current user wrapped into div with id equal to 'salutation'.
Called from L</render_page>.

=cut

sub render_salutation {
    my $cu = Jifty->web->current_user;
    div { attr {id => "salutation" };
        if ( $cu->id and $cu->user_object ) {
            _( 'Hiya, %1.', $cu->username );
        }
        else {
            _("You're not currently signed in.");
        }
    };
    return '';
}

=head3 render_jifty_page_detritus

Renders admin mode warning, the wait message, the keybindings and PubSub javascript.
Called from L</render_page>.

=cut

sub render_jifty_page_detritus {
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

    with( id => "jifty-wait-message", style => "display: none" ),
        div { _('Loading...') };

    div { id is "keybindings" };

    # This is required for jifty server push
    if ( Jifty->config->framework('PubSub')->{'Enable'} && Jifty::Subs->list )
    {
        script { outs_raw('new Jifty.Subs({}).start();') };
    }
}

1;
