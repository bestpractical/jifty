use strict;
use warnings;

package Jifty::Callback;

=head1 NAME

Jifty::Callback - Abstract base class for objects that can be called with keyword parameters

=head1 SYNOPSIS

    sub function_with_callback {
        my $cb = shift;
        $cb->call(with => "args");
    } 

    function_with_callback(Jifty::Callback::String->new("just a string"));
    function_with_callback(Jifty::Callback::Code->new(sub { some code }));
    function_with_callback(Jifty::Callback::Component->new("/path/to/component"));
    function_with_callback(Jifty::Callback::ComponentSource->new('<%args>...'));

    $callback->add_arguments( instead => "of", currying => "them" );

=cut

use base qw/Class::Accessor Jifty::Object/;

=head2 new CALLABLE

Creates a new callback object for the callable object CALLABLE.  For example:

  Jifty::Callback::String->new("some string")
  Jifty::Callback::Code->new(sub { ... })
  Jifty::Callback::Component->new("/_elements/something")
  Jifty::Callback::Component->new(Jifty->mason->current_comp)
  Jifty::Callback::ComponentSource->new('<%args>...')

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->callable(shift);
    $self->_arguments({});
    return $self;
} 

=head2 callable [CALLABLE]

Gets or sets the callable object.

=cut

__PACKAGE__->mk_accessors(qw/callable/);

=head2 add_arguments KEY1 => VAL1, ...

Saves the given keyword arguments so that when the callback is
C<call>ed, they will be passed in in addition to any arguments 
that are given then.

Returns itself, so that it can be chained.

=cut

__PACKAGE__->mk_accessors(qw/_arguments/);

sub add_arguments {
    my $self = shift;
    my %args = @_;

    while (my ($k, $v) = each %args) {
        $self->_arguments->{$k} = $v;
    } 

    return $self;
} 

=head2 call [KEY1 => VAL1, ...]

Calls the callback's "callable" with the given keyword arguments;
the exact meaning of "call" is defined by the subclass.  Any arguments
added with C<add_arguments> are also passed in, and they override any
arguments given here.  The return value is similarly defined by the subclass.

Within the C<Jifty> system, though, all callbacks are expected to output
something through C<< Jifty->framework->mason >>; note that for 
L<Jifty::Callback::Code>>, your subroutine must explicitly make calls to C<comp>
or C<out> on the mason object, whereas the other subclasses do that for you.

=cut

sub call {
    my $self = shift;
    $self->log->error("abstract base class method 'call' called on ", $self);
} 

=head2 call_arguments [KEY 1 => VAL1, ...]

Given keyword arguments, combines them with the arguments added with 
C<add_arguments> and returns the entire hash.  Meant to be used when writing
C<call> subroutines in subclasses:

    sub call {
        my $self = shift;
        my %args = $self->call_arguments(@_);
        # somehow call $self->callable using %args...
    }
    
=cut

sub call_arguments {
    my $self = shift;
    my %args = (@_, %{ $self->_arguments });
    return %args;
}

1;

