use warnings;
use strict;
 
package Jifty::Web::PageRegion;

=head1 NAME

Jifty::Web::PageRegion - Defines a page region

=head1 DESCRIPTION

Describes a region of the page which contains a Mason fragment which
can be updated via AJAX or via query parameters.

=cut

use base qw/Jifty::Object Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw(name force_path force_arguments default_path default_arguments qualified_name parent region_wrapper lazy loading_path class));
use Jifty::JSON;
use Encode ();

=head2 new PARAMHASH

Creates a new page region.  The possible arguments in the C<PARAMHASH>
are:

=over

=item name

The (unqualified) name of the region.  This is used to generate a
unique id -- it should consist of only letters and numbers.

=item path

The path to the fragment that this page region contains.  Defaults to
C</__jifty/empty>, which, as its name implies, is empty.

=item arguments (optional) (formerly 'defaults')

Specifies an optional set of parameter defaults.  These should all be
simple scalars, as they might be passed across HTTP if AJAX is used.

See L<Jifty::Web::Form::Element> for a list of the supported parameters.

=item force_arguments (optional)

Specifies an optional set of parameter values. They will override anything
sent by the user or set via AJAX.

=item force_path (optional)

A fixed path to the fragment that this page region contains.  Overrides anything set by the user.

=item parent (optional)

The parent L<Jifty::Web::PageRegion> that this region is enclosed in.

=item region_wrapper (optional)

A boolean; whether or not the region, when rendered, will include the
HTML region preamble that makes Javascript aware of its presence.
Defaults to true.

=item lazy (optional)

Delays the loading of the fragment until client render-time.
Obviously, does not work with downlevel browsers which don't uspport
javascript.

=item loading_path (optional)

The fragment to display while the client fetches the actual region.
Make this lightweight, or you'll be losing most of the benefits of
lazy loading!

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
                name => undef,
                path => "/__jifty/empty",
                defaults => {},
                parent => undef,
                force_arguments => {},
                force_path => undef,
                region_wrapper => 1,
                lazy => 0,
                loading_path => undef,
                @_
               );


    $args{'arguments'} ||= delete $args{'defaults'};

    # Name is required
    if (not defined $args{name}) {
        warn "Name is required for page regions.";
        return;
    }

    # References don't go over HTTP very well
    if (grep {ref $_} values %{$args{arguments}}) {
        warn "Reference '$args{arguments}{$_}' passed as default for '$_' to region '$args{name}'"
          for grep {ref $args{arguments}{$_}} keys %{$args{arguments}};
        return;
    }

    $self->name($args{name});
    $self->qualified_name(Jifty->web->qualified_region($self));
    $self->default_path($args{path});
    $self->default_arguments($args{arguments});
    $self->force_arguments($args{force_arguments});
    $self->force_path($args{force_path});
    $self->arguments({});
    $self->parent($args{parent} || Jifty->web->current_region);
    $self->region_wrapper($args{region_wrapper});
    $self->lazy($args{lazy});
    $self->loading_path($args{loading_path});
    $self->class($args{class});

    # Keep track of the fully qualified name (which should be unique)
    $self->log->warn("Repeated region: " . $self->qualified_name)
        if Jifty->web->get_region( $self->qualified_name );
    Jifty->web->{'regions'}{ $self->qualified_name } = $self;

    return $self;
}

=head2 name [NAME]

Gets or sets the name of the page region.

=cut

=head2 qualified_name [NAME]

Gets or sets the fully qualified name of the page region.  This should
be unique on a page.  This is usually set by L</enter>, based on the
page regions that this region is inside.  See
L<Jifty::Web/qualified_region>.

=cut

=head2 default_path [PATH]

Gets or sets the default path of the fragment.  This is overridden by
L</path>.

=cut

=head2 path [PATH]

Gets or sets the path that the fragment actually contains.  This
overrides L</default_path>.

=cut

sub path {
    my $self = shift;
    $self->{path} = shift if @_;
    return $self->{path} || $self->default_path;
}

=head2 default_argument NAME [VALUE]

Gets or sets the default value of the C<NAME> argument.  This is used
as a fallback, and also to allow generated links to minimize the
amount of state they must transmit.

=cut

sub default_argument {
    my $self = shift;
    my $name = shift;
    $self->{default_arguments}{$name} = shift if @_;
    return $self->{default_arguments}{$name} || '';
}

=head2 argument NAME [VALUE]

Gets or sets the actual run-time value of the page region.  This
usually comes from HTTP parameters.  It overrides the
L</default_argument> of the same C<NAME>.

=cut

sub argument {
    my $self = shift;
    my $name = shift;
    $self->{arguments}{$name} = shift if @_;
    return $self->force_arguments->{$name}||$self->{arguments}{$name} || $self->default_argument($name);
}

=head2 arguments [HASHREF]

Sets all arguments at once, or returns all arguments.  The latter will
also include all default arguments.

=cut

sub arguments {
    my $self = shift;
    $self->{arguments} = shift if @_;
    return { %{$self->{default_arguments}}, %{$self->{arguments}}, %{$self->force_arguments}};
}

=head2 enter

Enters the region; this sets the qualified name based on
L<Jifty::Web/qualified_region>, and uses that to pull runtime values
for the L</path> and L</argument>s from the
L<Jifty::Request/state_variables> before overriding them with the "force" versions.

=cut

sub enter {
    my $self = shift;

    # Add ourselves to the region stack
    push @{Jifty->web->{'region_stack'}}, $self;

    # Merge in the settings passed in via state variables
    for my $var (Jifty->web->request->state_variables) {
        my $key = $var->key;
        my $value = $var->value || '';

        if ($key =~ /^region-(.*?)\.(.*)/ and $1 eq $self->qualified_name and $value ne $self->default_argument($2)) {
            $self->argument($2 => $value);
        }
        if ($key =~ /^region-(.*)$/ and $1 eq $self->qualified_name and $value ne $self->default_path) {
            $self->path(URI::Escape::uri_unescape($value));
        }

        # We should always inherit the state variables from the uplevel request.
        Jifty->web->set_variable($key => $value);
    }

    for my $argument (keys %{$self->force_arguments}) {
            $self->argument($argument => $self->force_arguments->{$argument});
    }

    $self->path($self->force_path) if ($self->force_path);
}

=head2 exit 

Exits the page region, if it is the most recent one.  Normally, you
won't need to call this by hand; however, if you are calling L</enter>
by hand, you will need to call the corresponding C<exit>.

=cut

sub exit {
    my $self = shift;

    if (Jifty->web->current_region != $self) {
        $self->log->warn("Attempted to exit page region ".$self->qualified_name." when it wasn't the most recent");
    } else {
        pop @{Jifty->web->{'region_stack'}};
    }
}

=head2 as_string

Deals with the bulk of the effort to show a page region.  Returns a
string of the fragment and associated javascript (if any).

=cut

sub as_string {
    my $self = shift;
    Jifty->handler->buffer->push(private => 1, from => "PageRegion render of ".$self->path);
    $self->make_body;
    return Jifty->handler->buffer->pop;
}

=head2 render

Calls L</enter>, outputs the results of L</as_string>, and then calls
L</exit>.  Returns an empty string.

=cut

sub render {
    my $self = shift;

    $self->enter;
    $self->make_body;
    $self->exit;

    return '';
}

=head2 make_body

Outputs the results of the region to the current buffer.

=cut

sub make_body {
    my $self = shift;
    my $buffer = Jifty->handler->buffer;

    my %arguments = %{ $self->arguments };

    # undef arguments cause warnings. We hatesses the warnings, we do.
    defined $arguments{$_} or delete $arguments{$_} for keys %arguments;

    # We need to tell the browser this is a region and what its
    # default arguments are as well as the path of the "fragment".  We
    # do this by passing in a snippet of javascript which encodes this
    # information.  We only render this region wrapper if we're asked
    # to (which is true by default)
    if ( $self->region_wrapper ) {
         $buffer->append(qq|<script type="text/javascript">\n|
            . qq|new Region('| . $self->qualified_name . qq|',|
            . Jifty::JSON::objToJson( \%arguments, { singlequote => 1 } ) . qq|,| 
            . qq|'| . $self->path . qq|',|
            . ( $self->parent ? qq|'| . $self->parent->qualified_name . qq|'| : q|null|)
            . qq|,| . (Jifty->web->form->is_open ? '1' : 'null')
            . qq|);\n|
            . qq|</script>|);
        if ($self->lazy) {
            $buffer->append(qq|<script type="text/javascript">|
              . qq|jQuery(function(){ Jifty.update( { 'fragments': [{'region': '|.$self->qualified_name.qq|', 'mode': 'Replace'}], 'actions': {}}, document.getElementById('region-|.$self->qualified_name.qq|'))})|
              . qq|</script>|);
        }

        my $class = 'jifty-region';
        $class .= ' ' . $self->class if $self->class;
        $buffer->append(qq|<div id="region-| . $self->qualified_name . qq|" class="| . $class . qq|">|);

        if ($self->lazy) {
            if ($self->loading_path) {
                local $self->{path} = $self->loading_path;
                $self->render_as_subrequest(\%arguments);
            }
            $buffer->append(qq|</div>|);
            return;
        }
    }

    $self->render_as_subrequest(\%arguments);
    $buffer->append(qq|</div>|) if ( $self->region_wrapper );
}

=head2 render_as_subrequest

=cut

sub render_as_subrequest {
    my ($self, $arguments, $enable_actions) = @_;

    # Make a fake request and throw it at the dispatcher
    my $subrequest = Jifty->web->request->clone;
    $subrequest->argument( region => $self );
    # XXX: use ->arguments?
    $subrequest->argument( $_ => $arguments->{$_}) for keys %$arguments;
    $subrequest->template_arguments({});
    $subrequest->path( $self->path );
    $subrequest->top_request( Jifty->web->request->top_request );

    my %args;
    if ($self->path =~ m/\?/) {
        # XXX: this only happens if we are redirect within region AND
        # with continuation, which is already taken care of by the
        # clone.
        my ($path, $arg) = split(/\?/, $self->path, 2);
        $subrequest->path( $path );
        %args = (map { split /=/, $_ } split /&/, $arg);
        if ($args{'J:C'}) {
            $subrequest->continuation($args{'J:C'});
        }
    }
    # Remove all of the actions
    unless ($enable_actions) {
        $_->active(0) for ($subrequest->actions);
    }
    # $subrequest->clear_actions;
    local Jifty->web->{request} = $subrequest;
    if ($args{'J:RETURN'}) {
        my $top = Jifty->web->request->top_request;
        my $cont = Jifty->web->session->get_continuation($args{'J:RETURN'});
        $cont->return;
        # need to set this as subrequest again as it's clobbered by the return
        Jifty->web->request->top_request($top);
    }

    # Call into the dispatcher
    Jifty->handler->dispatcher->handle_request;

    return;
}

=head2 get_element [RULES]

Returns a CSS2 selector which selects only elements under this region
which fit the C<RULES>.  This method is used by AJAX code to specify
where to add new regions.

=cut

sub get_element {
    my $self = shift;
    return "#region-" . $self->qualified_name . ' ' . join(' ', @_);
}

=head2 client_cacheable

Returns the client cacheable state of the regions path. Returns false if the template has not been marked as client cacheable. Otherwise it returns the string "static" or "action" based uon the cacheable attribute set on the template.

=cut

sub client_cacheable {
    my $self = shift;
    my ($jspr) = Jifty->find_plugin('Jifty::Plugin::JSPageRegion') or return;

    return $jspr->client_cacheable($self->path);
}

=head2 client_cache_content

Returns the template as JavaScript code.

=cut

sub client_cache_content {
    my $self = shift;
    my ($jspr) = Jifty->find_plugin('Jifty::Plugin::JSPageRegion') or return;

    return $jspr->compile_to_js($self->path);
}

1;
