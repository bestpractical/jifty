use warnings;
use strict;
 
package Jifty::Web::Form::Clickable;

=head1 NAME

Jifty::Web::Form::Clickable - Some item that can be clicked on --
either a button or a link.

=head1 DESCRIPTION

=cut

use base qw/Jifty::Web::Form::Element Class::Accessor/;

=head2 accessors

=cut

sub accessors { shift->SUPER::accessors, qw(url escape_label continuation call return_values submit state) }
__PACKAGE__->mk_accessors(qw(url escape_label continuation call return_values submit state));

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;
    
    my %args = (
        url          => $root,
        label        => 'Click me!',
        class        => '',
        escape_label => 1,
        continuation => Jifty->web->request->continuation,
        submit       => [],
        state        => 0,
        @_,
    );

    $self->{parameters} = {};

    for (qw/continuation call/) {
        $args{$_} = $args{$_}->id if $args{$_} and ref $args{$_};
    }

    if ($args{submit}) {
        $args{submit} = [$args{submit}] unless ref $args{submit} eq "ARRAY";
        $args{submit} = [map {ref $_ ? $_->moniker : $_} @{$args{submit}}];
    }

    for my $field ( $self->accessors() ) {
        $self->$field( $args{$field} ) if exists $args{$field};
    }

    $self->parameter($_ => $args{parameters}{$_}) for %{$args{parameters}};

    # Anything doing fragment replacement needs to preserve the
    # current state as well
    if (grep {$self->$_} $self->handlers or $self->state) {
        for (Jifty->web->request->state_variables) {
            if ($_->key =~ /^region-(.*?)\.(.*)$/) {
                $self->region_argument($1, $2 => $_->value);
            } elsif ($_->key =~ /^region-(.*)$/) {
                $self->region_fragment($1, $_->value);
            } else {
                $self->state_variable($_->key => $_->value) 
            }
        }
    }

    return $self;
}

=head2 url

The URL of the link; defaults to the current URL.

=head2 escape_label

HTML escape the label? Defaults to true

=head2 call

If clicking on the button pops the continuation stack, thus returning
a value to the continuation that we are currently in.  This does not
affect the button if there is no current continuation.

=head2 return_values

=head2 parameter KEY VALUE

Sets the given C<KEY> to the given C<VALUE>.  Empty or undefined
C<VALUE>s will not be sent.

=cut

sub parameter {
    my $self = shift;
    my ($key, $value, $fallback) = @_;
    if (defined $value and length $value) {
        $self->{parameters}{$key} = $value;        
    } else {
        delete $self->{parameters}{$key};
        $self->{fallback}{$key} = $fallback;
    }
}

=head2 state_variable KEY VALUE

Sets the state variable named C<KEY> to C<VALUE>.

=cut

sub state_variable {
    my $self = shift;
    my ($key, $value, $fallback) = @_;
    $self->parameter("J:V-$key" => $value, $fallback);
}

=head2 region_fragment NAME PATH

Sets the path of the fragment named C<NAME> to be C<PATH>.

=cut

sub region_fragment {
    my $self = shift;
    my ($region, $fragment) = @_;

    my $defaults = Jifty->web->get_region($region);

    if ($defaults and $fragment eq $defaults->default_path) {
        $self->state_variable("region-$region" => undef, $fragment);
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

    my $defaults = Jifty->web->get_region($region);

    if ($defaults and $value eq $defaults->default_argument($argument)) {
        $self->state_variable("region-$region.$argument" => undef, $value);
    } else {
        $self->state_variable("region-$region.$argument" => $value)
    }
      
}

=head2 parameters

=cut

sub parameters {
    my $self = shift;

    my %parameters = %{$self->{parameters}};

    $parameters{"J:CALL"} = $self->call
      if $self->call;

    $parameters{"J:C"} = $self->continuation
      if $self->continuation and not $self->call;

    if ($self->return_values) {
        my %return_values = %{$self->return_values};
        $parameters{"J:C-$_"} = $return_values{$_} for keys %return_values;
        $parameters{"J:PATH"} = $self->url;
    }

    return %parameters;
}

=head2 post_parameters

=cut

sub post_parameters {
    my $self = shift;

    my %parameters = ($self->parameters, %{$self->{fallback} || {}});

    # Actions to be submitted
    $parameters{"J:ACTIONS"} = join(';', @{$self->submit}) if $self->submit;

    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;

    # Add a redirect, if this isn't to the right page
    if ($self->url ne $root and not $self->return_values) {
        require Jifty::Action::Redirect;
        my $redirect = Jifty::Action::Redirect->new(arguments => {url => $self->url});
        $parameters{$redirect->register_name} = ref $redirect;
        $parameters{$redirect->form_field_name('url')} = $self->url;
    }

    return %parameters;
}

=head2 get_parameters

=cut

sub get_parameters {
    my $self = shift;

    my %parameters = $self->parameters;

    return %parameters;
}

=head2 complete_url

=cut

sub complete_url {
    my $self = shift;

    my %parameters = $self->get_parameters;

    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;
    my $url = $self->return_values ? $root : $self->url;
    if (%parameters) {
        $url .= ($url =~ /\?/) ? ";" : "?";
        $url .= Jifty->web->query_string(%parameters);
    }
    
    return $url;
}

=head2 as_link

=cut

sub as_link {
    my $self = shift;

    my %args;
    $args{$_} = $self->$_ for grep {defined $self->$_} $self->SUPER::accessors;
    my $link = Jifty::Web::Form::Link->new( %args,
                                            escape_label => $self->escape_label,
                                            url => $self->complete_url,
                                            @_
                                          );
    return $link;
}

=head2 as_button

=cut

sub as_button {
    my $self = shift;

    my %args;
    $args{$_} = $self->$_ for grep {defined $self->$_} $self->SUPER::accessors;
    my $field = Jifty::Web::Form::Field->new( %args,
                                              type => 'InlineButton',
                                              @_
                                            );
    my %parameters = $self->post_parameters;

    $field->input_name(join "|", map {$_."=".$parameters{$_}} grep {defined $parameters{$_}} keys %parameters);
    $field->name(join '|', keys %{$args{parameters}});

    return $field;
}

sub generate {
    my $self = shift;

    for my $trigger ($self->handlers) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = ref $value eq "ARRAY" ? @{$value} : ($value);
        for my $hook (@hooks) {
            $hook->{region} ||= Jifty->web->qualified_region;
            $hook->{args} ||= {};

            $self->region_fragment($hook->{region}, $hook->{fragment}) if $hook->{fragment};
            $self->region_argument($hook->{region}, $_ => $hook->{args}{$_}) for keys %{$hook->{args}};
            if ($hook->{submit}) {
                $self->{submit} ||= [];
                push @{$self->{submit}}, ref $hook->{submit} ? $hook->{submit}->moniker : $hook->{submit};
            }
        }
    }

    return ((not($self->submit) || @{$self->submit}) ? $self->as_button(@_) : $self->as_link(@_));
}

1;
