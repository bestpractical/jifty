use warnings;
use strict;

package Jifty::Result;

=head1 NAME

Jifty::Result - Outcome of running a L<Jifty::Action>

=head1 DESCRIPTION

C<Jifty::Result> encapsulates the outcome of running a L<Jifty::Action>.
Results are also stored on the framework's L<Jifty::Response> object.
The response is stored in the session during a redirect, so the
information is still accessible even after a redirect.

=cut

use Jifty::Everything;

use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors(qw(failure action_class message error _content));


=head2 new

Construct a new action result.  This is done automatically when the
action is created, and can be accessed via the C<result> method on the
action.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->failure(0);
    $self->_content({});

    return $self;
}

=head2 failure [BOOL]

Gets or sets if the action succeeded or failed.

=head2 success [BOOL]

Gets or success if the action succeeded or failed -- this is an
alternate interface from C<failure> but has the same effect.

=cut

sub success {
    my $self = shift;
    return not $self->failure(map {not $_} @_);
}

=head2 action_class [MESSAGE]

Returns the class for the action that this result came from.


=head2 message [MESSAGE]

Gets or sets the action's response message.  This is an informational
textual description of the outcome of the action.

=head2 error [ERROR]

Gets or sets the action's error response.  This is an informational
textual description of what went wrong with the action, overall.  This
also automatically sets the result to be a L</failure>.

=cut

sub error {
    my $self = shift;
    
    $self->failure(1) if @_ and $_[0];
    $self->{error} = shift if @_;
    return $self->{error};
}

=head2 field_error FIELD [ERROR]

Gets or sets the error string for a specific field on the action.
This also automatically sets the result to be a failure.

=cut

sub field_error {
    my $self = shift;
    my $field = shift;

    $self->failure(1) if @_ and $_[0];
    $self->{field_errors}{ $field } = shift if @_;
    return $self->{field_errors}{ $field };
}

=head2 field_errors

Returns a hash which maps argument name to error.

=cut

sub field_errors {
    my $self = shift;
    return %{$self->{field_errors}};
}

=head2 content [KEY [, VALUE]]

Gets or sets the content C<KEY>.  This is used when actions need to
return values.  If not C<KEY> is passed, it returns an anonymous hash
of all of the C<KEY> and C<VALUE> pairs.

=cut

sub content {
    my $self = shift;

    return $self->_content unless @_;

    my $key = shift;
    $self->_content->{$key} = shift if @_;
    return $self->_content->{$key};
}

1;
