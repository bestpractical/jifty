use warnings;
use strict;
 
package Jifty::Web::PageRegion;

=head1 NAME

Jifty::Web::PageRegion - Defines a page region

=head1 DESCRIPTION

Describes a region of the page which contains a mason fragment which
can be updated via AJAX or via query parameters.

=cut

use base qw/Jifty::Object Class::Accessor/;
__PACKAGE__->mk_accessors(qw(name default_path default_arguments qualified_name parent region_wrapper));
use Jifty::JSON;

=head2 new PARAMHASH

Creates a new page region.  The possible arguments in the C<PARAMHASH>
are:

=over

=item name

The (unqualified) name of the region.  This is used to generate a
unique id -- it should consist of only letters and numbers.

=item path

The path to the fragment that this page region contains.  This B<must>
be under a C</fragments> path.

=item defaults (optional)

Specifies an optional set of parameter defaults.  These should all be
simple scalars, as they might be passed across HTTP if AJAX is used.

=item parent (optional)

The parent L<Jifty::Web::PageRegion> that this region is enclosed in.

=item region_wrapper (optional)

A boolean; whether or not the region, when rendered, will include the
HTML region preamble that makes Javascript aware of its presence.
Defaults to false, as this is usually handled by Mason components.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
                name => undef,
                path => undef,
                defaults => {},
                _bootstrap => undef,
                parent => undef,
                region_wrapper => 1,
                @_
               );

    # Name and path are required
    if (not $args{_bootstrap} and (not defined $args{name} or not defined $args{path})) {
        warn "Name and path are required for page regions. We got ".join(",", %args);
        return;
    }

    # References don't go over HTTP very well
    if (grep {ref $_} values %{$args{defaults}}) {
        warn "Reference '$args{defaults}{$_}' passed as default for '$_' to region '$args{name}'"
          for grep {ref $args{defaults}{$_}} keys %{$args{defaults}};
        return;
    }

    $self->name($args{name});
    $self->default_path($args{path});
    $self->default_arguments($args{defaults});
    $self->arguments({});
    $self->parent($args{parent});
    $self->region_wrapper(not $args{_bootstrap} and $args{region_wrapper});

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
    return $self->{arguments}{$name} || $self->default_argument($name);
}

=head2 arguments [HASHREF]

Sets all arguments at once, or returns all arguments.  The latter will
also include all default arguments.

=cut

sub arguments {
    my $self = shift;
    $self->{arguments} = shift if @_;
    return { %{$self->{default_arguments}}, %{$self->{arguments}}};
}

=head2 enter

Enters the region; this sets the qualified name based on
L<Jifty::Web/qualified_region>, and uses that to pull runtime values
for the L</path> and L</argument>s from the
L<Jifty::Request/state_variables>.

=cut

sub enter {
    my $self = shift;

    $self->qualified_name(Jifty->web->qualified_region);

    # Merge in the settings passed in via state variables
    for (Jifty->web->request->state_variables) {
        if ($_->key =~ /^region-(.*?)\.(.*)/ and $1 eq $self->qualified_name and $_->value ne $self->default_argument($2)) {
            $self->argument($2 => $_->value);
            Jifty->web->set_variable("region-$1.$2" => $_->value);
        }
        if ($_->key =~ /^region-(.*?)$/ and $1 eq $self->qualified_name and $_->value ne $self->default_path) {
            $self->path($_->value);
            Jifty->web->set_variable("region-$1" => $_->value);
        }
    }
}

=head2 render

Returns a string of the fragment and associated javascript.

=cut

sub render {
    my $self = shift;

    my %arguments =  %{$self->arguments};

    # undef arguments cause warnings. We hatesses the warnings, we do.
    defined $arguments{$_} or delete $arguments{$_} for keys %arguments;
    my $result = "";

    # Map out the arguments
    for (keys %arguments) {
        my ($key, $value) = Jifty::Request::Mapper->map(destination => $_, source => $arguments{$_});
        next unless $key ne $_;
        delete $arguments{$_};
        $arguments{$key} = $value;
    }

    # We need to tell the browser this is a region and
    # what its default arguments are as well as the path of the "fragment".
    
    # We do this by passing in a snippet of javascript which encodes this 
    # information.

    # Alex is sad about: Anything which is replaced _must_ start life as a fragment.
    # We don't have a good answer for this yet.

    # We only render the region wrapper if we're asked to (which is true by default)
    if ($self->region_wrapper) {
        $result .= qq|<script type="text/javascript">\n|;
        $result .= qq|new Region('|. $self->qualified_name .qq|',|;
        $result .= Jifty::JSON::objToJson(\%arguments, {quotapos => 1});
        $result .= qq|,'|. $self->path . qq|');\n|;
        $result .= qq|</script>|;
        $result .= qq|<div id="region-| . $self->qualified_name . qq|">|;
    }

    # Use a subrequest so we can't show components we wouldn't
    # normally be allowed to.  We pass in an empty 'J:ACTIONS' so that
    # actions don't get run more than once.

    Jifty->web->mason->make_subrequest
      ( comp => $self->path,
        args => [ %{ Jifty->web->request->arguments },
                  region => $self,
                  'J:ACTIONS' => '',
                  %arguments ],
        out_method => \$result,
      )->exec;

    if ($self->region_wrapper) {
        $result .= qq|</div>|;
    }

    return $result;
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

1;
