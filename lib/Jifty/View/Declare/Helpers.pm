use warnings;
use strict;

package Jifty::View::Declare::Helpers;
use Template::Declare::Tags;
use base qw/Template::Declare Exporter/;

our @EXPORT = (
    qw(hyperlink tangent redirect new_action
    form_submit form_return form_next_page page content
    wrapper request get set render_param render_hidden
    render_action render_region render_mason mason_scomp
    current_user js_handlers),
    @Template::Declare::Tags::EXPORT,
    @Template::Declare::Tags::TagSubs,  # Backward compatibility only
    @Template::Declare::Tags::TAG_SUB_LIST,
);

=head1 NAME

Jifty::View::Declare::Helpers - Additional subroutines for Jifty TD templates

=head1 DESCRIPTION

This library provides mixins to help build your application's user interface.

=head1 METHODS

=head2 Arguments

=head3 get args

Returns arguments as set in the dispatcher or with L</set> below.
If called in scalar context, pulls the first item in C<args> and returns it.
If called in list context, returns the values of all items in C<args>.

    my $action = get('action');
    my ($action, $object) = get(qw(action object));

=cut

sub get {
    if (wantarray) {
        map { _get_single($_) } @_;
    } else {
        _get_single($_[0]);
    }
}

sub request; # defined later

sub _get_single {
    my $v = request->template_argument($_[0]) || request->argument( $_[0] );
    return $v if defined $v;

    if (request->top_request ne request() and $v = request->top_request->template_argument($_[0])) {
        if (ref $v) {
            warn("The template argument '$_[0]' was not explicitly passed to the current region ('@{[request->path]}'), and thus will not work if the region is ever refreshed.  Unfortunately, it is a reference, so it can't be passed explicitly either.  You'll need to explicitly pass some stringification of what it is to the region.".Carp::longmess);
        } else {
            warn("The template argument '$_[0]' was not explicitly passed to the the current region ('@{[request->path]}'), and thus will not work if the region is ever refreshed.  Try passing it explicitly?");
        }
    }
    return undef;
}

=head3 set key => val [ key => val ...]

Sets arguments for later grabbing with L<get>.

=cut

sub set {
    while ( my ( $arg, $val ) = splice(@_, 0, 2) ) {
        request->template_argument( $arg => $val );
    }
}

=head2 HTML pages and layouts

=head3 page

 template 'foo' => page {{ title is 'Foo' } ... };

  or

 template 'foo' => page { title => 'Foo' } content { ... };

Renders an HTML page wrapped in L</wrapper>, after calling
"/_elements/nav" and setting a content type. Generally, you shouldn't
be using "/_elements/nav" but a Dispatcher rule instead.

If C<page/content> calling convention is used, the return value of the
first sub will be passed into wrapper as the second argument as a
hashref, as well as the last argument for the content sub.

=cut

sub page (&;$) {
    unshift @_, undef if $#_ == 0;
    my ( $meta, $code ) = @_;
    my $ret = sub {
        my $self = shift;
        Jifty->handler->apache->content_type('text/html; charset=utf-8');
        my $wrapper = Jifty->app_class('View')->can('wrapper') || \&wrapper;
        my @metadata = $meta ? $meta->($self) : ();
        my $metadata = $#metadata == 0 ? $metadata[0] : {@metadata};
        local *is::title = sub { Carp::carp "Can't use 'title is' when mixing mason and TD" };
        $wrapper->( sub { $code->( $self, $metadata ) }, $metadata );
    };
    $ret->() unless defined wantarray;
    return $ret;
}

=head3 content

Helper function for page { ... } content { ... }, read L</page> instead.

=cut

sub content (&;$) {
    # XXX: Check for only 1 arg
    return $_[0];
}

=head3 wrapper $coderef

Render a page. $coderef is a L<Template::Declare> coderef. 
This badly wants to be redone.

=cut

sub wrapper {
    my $content_code = shift;
    my $meta = shift;
    my $page = _page_class()->new({ content_code => $content_code, _meta => $meta });

    my ($spa) = Jifty->find_plugin('Jifty::Plugin::SinglePage');

    # XXX: spa hooks should be moved to page handlers
    if ($spa && $page->allow_single_page) {
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
        $page->render;
    }
}

sub _page_class {
    my $hard_require = 0;
    my $app_class = get_current_attr('PageClass');;
    delete $Template::Declare::Tags::ATTRIBUTES{ 'PageClass' };
    $hard_require = 1 if $app_class;

    my $page_class = Jifty->app_class( $app_class || 'View::Page' );
    $page_class = 'Jifty::View::Declare::Page'
        unless Jifty::Util->_require( module => $page_class, quiet => !$hard_require );
    # XXX: fallback, this is ugly
    Jifty::Util->require( $page_class );
    return $page_class;
}

=head2 Forms and actions

=head3 form CODE

Takes a subroutine reference or block of perl as its only argument and renders it as a Jifty C<form>,
for example:

    my $action = new_action class => 'CreateTask';
    form {
        form_next_page url => '/';
        render_action $action;
        form_submit( label => _('Create') );
    };

=cut

{
    no warnings qw/redefine/;
    sub form (&;$) {
        my $code = shift;

        smart_tag_wrapper {
          outs_raw( Jifty->web->form->start(@_) );
          $code->();
          outs_raw( Jifty->web->form->end );
          return '';
        };
    }
}

=head3 new_action

Shortcut for L<Jifty::Web/new_action>.

=cut

sub new_action(@) {
    return Jifty->web->new_action(@_);
}

=head3 render_action $action_object, $fields, $args_to_pass_to_action

Renders an action out of whole cloth.

Arguments

=over 4

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

=head2 render_param $action, $param, %args

Takes an action and one or more arguments to pass to
L<< Jifty::Action->form_field >>.

=cut

sub render_param {
    my $action = shift;
    outs_raw( $action->form_field(@_) );
    return '';
}

=head2 render_hidden $action $name $default @args

Takes an action and one or more arguments to pass to L<< Jifty::Action->hidden >>

=cut

sub render_hidden {
    my $action = shift;
    outs_raw( $action->hidden(@_) );
    return '';
}

=head3 form_return

Shortcut for L<Jifty::Web::Form/return>.

=cut

sub form_return(@) {
    outs_raw( Jifty->web->form->return(@_) );
    '';
}

=head3 form_submit

Shortcut for L<Jifty::Web::Form/submit>.

=cut

sub form_submit(@) {
    outs_raw( Jifty->web->form->submit(@_) );
    '';
}

=head3 form_next_page

Shortcut for L<Jifty::Web::Form/next_page>.

=cut

sub form_next_page(@) {
    Jifty->web->form->next_page(@_);
}

=head2 Other functions and shortcutxs

=head3 hyperlink

Shortcut for L<Jifty::Web/link>.

=cut

sub hyperlink(@) {
    _function_wrapper( link => @_);
}

sub _function_wrapper {
    my $function = shift;
    Template::Declare->buffer->append( Jifty->web->$function(@_)->render || '' );
    return '';
}


=head3 tangent

Shortcut for L<Jifty::Web/tangent>.

=cut

sub tangent(@) {
    _function_wrapper( tangent => @_);
}

=head3 redirect

Shortcut for L<Jifty::Web/redirect>.

=cut

sub redirect(@) {
    Jifty->web->redirect(@_);
    return '';
}

=head3 render_region 

A shortcut for C<< Jifty::Web::PageRegion->new(@_)->render >> which does the
L<Template::Declare> magic necessary to not mix its output with your current
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
    Jifty::Web::PageRegion->new(%$args)->render;
}


=head3 request

Shortcut for L<Jifty::Web/request>.

=cut

sub request {
    Jifty->web->request;
}

=head3 current_user

Shortcut for L<Jifty::Web/current_user>.

=cut


sub current_user {
    Jifty->web->current_user;
}

=head3 js_handlers

Allows you to put javascript handlers, a la
L<Jifty::Web::Form::Element>, onto arbitrary HTML elements:

  div {
      js_handlers {
          onclick => { path => "/some/region/path" }
      }
  }

=cut

sub js_handlers(&;@) {
    my $code = shift;
    my $element = Jifty::Web::Form::Element->new({$code->()});
    my %js = $element->javascript_attrs;
    Template::Declare::Tags::append_attr($_ => $js{$_}) for keys %js;
    return @_;
}

=head3 render_mason PATH, ARGS

Renders the Mason template at C<PATH> (a string) with C<ARGS> (a hashref).

=cut

sub render_mason {
    my ($template, $args) = @_;
    my $mason = Jifty->handler->view('Jifty::View::Mason::Handler');
    $mason->handle_comp($template, $args);
    return '';
}

=head3 mason_scomp PATH, ARGS

Executes the Mason template at C<PATH> (a string) with C<ARGS> (a hashref) and
returns its results as a string.

=cut

sub mason_scomp {
    my ($template, $args) = @_;
    my $mason = Jifty->handler->view('Jifty::View::Mason::Handler');
    return $mason->handle_scomp($template, $args);
}

1;
