use warnings;
use strict;

package Jifty::View::Declare::Helpers;
use base qw/Template::Declare/;
use base qw/Exporter/;
use Template::Declare::Tags;

our @EXPORT = ( qw(form hyperlink tangent redirect new_action form_submit form_return  form_next_page page wrapper request get set render_param current_user render_action render_region), @Template::Declare::Tags::EXPORT);

=head1 NAME

Jifty::View::Declare::Helpers

=head1 DESCRIPTION

This library provides mixins to help build your application's user interface.

=head1 METHODS




=head2 form CODE

Takes a subroutine reference or block of perl as its only argument and renders it as a Jifty C<form>. 


=cut

 {
    no warnings qw/redefine/;
    sub form (&) {
        my $code = shift;

        smart_tag_wrapper {
          outs_raw( Jifty->web->form->start(@_) );
          $code->();
          outs_raw( Jifty->web->form->end );
          return '';
        };
    }
 }


=head2 hyperlink 

Shortcut for L<Jifty::Web/link>.

=cut

sub hyperlink(@) {
    _function_wrapper( link => @_);
}

sub _function_wrapper {
    my $function = shift;
    Template::Declare->new_buffer_frame;
    my $once= Jifty->web->$function(@_)->render || '';
    my $content = Template::Declare->buffer->data() ||'';
    Template::Declare->end_buffer_frame;
    outs_raw( $content.$once); 
    return '';


}


=head2 tangent

Shortcut for L<Jifty::Web/tangent>.

=cut


sub tangent(@) {
    _function_wrapper( tangent => @_);
}

=head2 redirect

Shortcut for L<Jifty::Web/redirect>.

=cut

sub redirect(@) {
    Jifty->web->redirect(@_);
    return '';
}

=head2 new_action

Shortcut for L<Jifty::Web/new_action>.

=cut

sub new_action(@) {
    return Jifty->web->new_action(@_);
}


=head2 render_region 

A shortcut for Jifty::Web::PageRegion->new(@_)->render which does the
Template::Declare magic necessary to not mix its output with your current
page's.


=cut

sub render_region(@) {
    unshift @_, 'name' if @_ % 2;
    my $args = {@_};
    my $path = $args->{path} ||= '/__jifty/empty';
    if ($Template::Declare::Tags::self && $path !~ m|^/|) {
	$args->{path} = $Template::Declare::Tags::self->path_for($path);
    }
    local $Template::Declare::Tags::self = undef;
    Template::Declare->new_buffer_frame;
    Jifty::Web::PageRegion->new(%$args)->render;
    my $content = Template::Declare->buffer->data();
    Template::Declare->end_buffer_frame;
    Jifty->web->out($content);
}


=head2 render_action $action_object, $fields, $args_to_pass_to_action

Renders an action out of whole cloth.

Arguments

=over 

=item $action_object

A Jifty::Action object which has already been initialized

=item $fields

A reference to an array of fields that should be rendered when
displaying this action. If left undefined, all of the 
action's fields will be rendered.

=item $args_to_pass_to_action

A hashref of arguments that should be passed to $action->form_field for
every field of this action.

=back


=cut

sub render_action(@) {
    my ( $action, $fields, $field_args ) = @_;
   
    my @f = ($fields && ref ($fields) eq 'ARRAY') ? @$fields : $action->argument_names;
    foreach my $argument (@f) {
        outs_raw( $action->form_field( $argument, %$field_args ) );
    }
}

=head2 form_return

Shortcut for L<Jifty::Web::Form/return>.

=cut

sub form_return(@) {
    outs_raw( Jifty->web->form->return(@_) );
    '';
}

=head2 form_submit

Shortcut for L<Jifty::Web::Form/submit>.

=cut

sub form_submit(@) {
    outs_raw( Jifty->web->form->submit(@_) );
    '';
}

=head2 form_next_page

Shortcut for L<Jifty::Web::Form/next_page>.

=cut


sub form_next_page(@) {
    Jifty->web->form->next_page(@_);
}

=head2 request

Shortcut for L<Jifty::Web/request>.

=cut

sub request {
    Jifty->web->request;
}

=head2 current_user

Shortcut for L<Jifty::Web/current_user>.

=cut


sub current_user {
    Jifty->web->current_user;
}

=head2 get args

Returns arguments as set in the dispatcher or with L</set> below.
If called in scalar context, pulls the first item in C<args> and returns it.
If called in list context, returns the values of all items in C<args>.



=cut

sub get {
    if (wantarray) {
        map { request->argument($_) } @_;
    } else {
        request->argument( $_[0] );
    }
}


=head2 set key => val [ key => val ...]

Sets arguments for later grabbing with L<get>.


=cut


sub set {
    while ( my ( $arg, $val ) = splice(@_, 0, 2) ) {
        request->argument( $arg => $val );
    }

}

=head2 render_param $action @args

Takes an action and one or more arguments to pass to L<Jifty::Action->form_field>.

=cut

sub render_param {
    my $action = shift;
    outs_raw( $action->form_field(@_) );
    return '';
}

=head2 page 

 template 'foo' => page {{ title is 'Foo' } ... };

Renders an HTML page wrapped in L</wrapper>, after calling
"/_elements/nav" and setting a content type. Generally, you shouldn't
be using "/_elements/nav" but a Dispatcher rule instead.

=cut

sub page (&) {
    my $code = shift;
    sub {
        my $self = shift;
        Jifty->handler->apache->content_type('text/html; charset=utf-8');
        if ( my $wrapper = Jifty->app_class('View')->can('wrapper') ) {
            $wrapper->(sub { $code->($self)});
        } else {

        wrapper(sub { $code->($self) });
    }
    };
}



=head2 wrapper $coderef

Render a page. $coderef is a L<Template::Declare> coderef. 
This badly wants to be redone.

=cut

sub wrapper ($) {
    my $page_class = Jifty->app_class('View::Page');
    $page_class = 'Jifty::View::Declare::Page'
        unless Jifty::Util->_require( module => $page_class, quiet => 1 );
    # XXX: fallback, this is ugly
    Jifty::Util->require( $page_class );

    my $page = $page_class->new({ content_code => shift });

    my ($spa) = Jifty->find_plugin('Jifty::Plugin::SinglePage');

    if ($spa) {
	# If it's a single page app, we want to either render a
	# wrapper and then get the region or render just the content
        if ( !Jifty->web->current_region ) {
	    $page->render_header;
            $page->render_body(sub {
                render_region( $spa->region_name,
                    path => Jifty->web->request->path );
            });
	    $page->render_footer;
        } else {
	    $page->done_header(1);
	    $page->render_page->();
        }
    }
    else {
	$page->render_body( sub { $page->render_page->() });
	$page->render_footer;
    }
}




1;
