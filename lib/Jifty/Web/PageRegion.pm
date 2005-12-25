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
__PACKAGE__->mk_accessors(qw(name default_path default_arguments qualified_name));

=head2 new PARAMHASH

Creates a new page region.  The possible arguments in the C<PARAMHASH>
are:

=over

=item name (required)

The (unqualified) name of the region.  This is used to generate a
unique id -- it should consist of only letters and numbers.

=item path (required)

The path to the fragment that this page region contains.  This B<must>
be under a C</fragments> path.

=item defaults (optional)

Specifies an optional set of parameter defaults.  These should all be
simple scalars, as they might be passed across HTTP if AJAX is used.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
                name => undef,
                path => undef,
                defaults => {},
                @_
               );

    # Name and path are required
    unless (defined $args{name} and defined $args{path}) {
        warn "Name and path are required for page regions";
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
    return $self->{default_arguments}{$name} || "";
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

    $self->qualified_name(Jifty->framework->qualified_region);
    
    # Merge in the settings passed in via state variables
    for (Jifty->framework->request->state_variables) {
        $self->argument($2 => $_->value) if $_->key =~ /^region-(.*?)\.(.*)/ and $1 eq $self->qualified_name;
        $self->path($_->value) if $_->key =~ /^region-(.*?)$/ and $1 eq $self->qualified_name;
    }
}

=head2 render

Returns a string of the fragment and associated javascript.

=cut

sub render {
    my $self = shift;

    # Make sure we're going to someplace sane
    if ($self->path !~ m|/fragments/| or $self->path =~ /\.\./) {
        warn "Attempt to call disallowed path '@{[$self->path]}' in region @{[$self->qualified_name]}";
        return;
    }

    my %arguments = %{$self->arguments};
    my $result = "";
    $result .= qq|<script type="text/javascript"><!--\n|;
    $result .= qq|region('|. $self->qualified_name .qq|',{|;
    $result .= join(',', map {($a = $arguments{$_})=~s/'/\\'/g;qq|'$_':'$a'|} keys %arguments);
    $result .= qq|},'|. $self->path . qq|');\n|;
    $result .= qq| --></script>|;
    $result .= qq|<div id="region-| . $self->qualified_name . qq|">|;
    $result .= Jifty->framework->mason->scomp($self->path,
                                              region => $self->name,
                                              qualified_region => $self->qualified_name,
                                              %arguments);
    $result .= qq|</div>|;

    return $result;
}

1;
