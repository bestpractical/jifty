use warnings;
use strict;
 
package Jifty::Web::Form::Link;

=head1 NAME

Jifty::Web::Form::Link - Creates a state-preserving HTML link

=head1 DESCRIPTION

Describes an HTML link that may be AJAX-enabled.

=cut

use base qw/Jifty::Web::Form::Element Class::Accessor/;
use URI;

sub accessors { shift->SUPER::accessors(), qw(url label); }
__PACKAGE__->mk_accessors(qw(url label));

=head2 new PARAMHASH

Creates a new L<Jifty::Web::Form::Link> object.  Possible arguments to
the C<PARAMHASH> are:

=over

=item url (optional)

The URL of the link; defaults to the current URL.

=item label

The text of the link

=item parameters (optional)

A hashref of default parameters to append to the url.

=back

The parameters may also include AJAX hooks; see
L<Jifty::Web::Form::Element>.

The link automatically persists any L<Jifty::Request/state_variables>
that were set in the previous request.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
                url   => $ENV{PATH_INFO},
                label => undef,
                parameters => {},
                @_
               );

    for my $field ( $self->accessors() ) {
        $self->$field( $args{$field} ) if exists $args{$field};
    }
    $self->{parameter} = {};

    for (Jifty->framework->request->state_variables) {
        if ($_->key =~ /^region-(.*?)\.(.*)$/) {
            $self->region_argument($1, $2 => $_->value);
        } elsif ($_->key =~ /^region-(.*)$/) {
            $self->region_fragment($1, $_->value);
        } else {
            $self->state_variable($_->key => $_->value) 
        }
    }
    $self->parameter($_ => $args{parameters}{$_}) for %{$args{parameters}};

    return $self;
}

=head2 url [URL]

Gets or sets the URL that the link links to.

=cut

=head2 label [TEXT]

Gets or sets the text of the link itself.

=cut

=head2 parameter KEY VALUE

Sets the given C<KEY> to the given C<VALUE>.  Empty or undefined
C<VALUE>s will not be sent.

=cut

sub parameter {
    my $self = shift;
    my ($key, $value) = @_;
    if (defined $value and length $value) {
        $self->{parameter}{$key} = $value
    } else {
        delete $self->{parameter}{$key};
    }
}

=head2 state_variable KEY VALUE

Sets the state variable named C<KEY> to C<VALUE>.

=cut

sub state_variable {
    my $self = shift;
    my ($key, $value) = @_;
    $self->parameter("J:V-$key" => $value);
}

=head2 region_fragment NAME PATH

Sets the path of the fragment named C<NAME> to be C<PATH>.

=cut

sub region_fragment {
    my $self = shift;
    my ($region, $fragment) = @_;

    my $defaults = Jifty->framework->get_region($region);

    if ($defaults and $fragment eq $defaults->default_path) {
        $self->state_variable("region-$region" => undef);
    } else {
        $self->state_variable("region-$region" => $fragment);
    }
}

=head2 region_argument NAME ARG VALUE

Sets the value of the C<ARG> argument on the fragment named C<NAME> to
C<VALUE>.

=cut

sub region_argument {
    my $self = shift;
    my ($region, $argument, $value) = @_;

    my $defaults = Jifty->framework->get_region($region);

    if ($defaults and $value eq $defaults->default_argument($argument)) {
        $self->state_variable("region-$region.$argument" => undef);
    } else {
        $self->state_variable("region-$region.$argument" => $value)
    }
      
}

=head2 parameters

Returns a hash of all parameters that have been set.

=cut

sub parameters {
    my $self = shift;

    return %{$self->{parameter}};
}

=head2 render

Returns a string of the link, including any necessary javascript.

=cut

sub render {
    my $self = shift;

    for my $trigger ($self->handlers) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = ref $value eq "ARRAY" ? @{$value} : ($value);
        for my $hook (@hooks) {
            $hook->{region} ||= Jifty->framework->qualified_region;
            $hook->{args} ||= {};

            $self->region_fragment($hook->{region}, $hook->{fragment}) if $hook->{fragment};
            $self->region_argument($hook->{region}, $_ => $hook->{args}{$_}) for keys %{$hook->{args}};
        }
    }
    
    my $uri = URI->new($self->url);
    $uri->query_form($self->parameters);

    return qq!<a href="$uri"! . $self->javascript() . ">". $self->label ."</a>";;
}

1;
