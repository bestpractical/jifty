use warnings;
use strict;

package Jifty::API;

=head1 NAME

Jifty::API - Manages and allow reflection on the Jifty::Actions that
make up a Jifty application's API

=cut

use Jifty::Everything;
use base qw/Class::Accessor Jifty::Object/;

require Module::Pluggable;

__PACKAGE__->mk_accessors(qw(action_limits));

=head1 METHODS

=head2 new

Creates a new C<Jifty::API> object

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->reset;

    Module::Pluggable->import(
        search_path => [
            Jifty->config->framework('ActionBasePath'),
            Jifty->config->framework('ApplicationClass') . "::Action",
            "Jifty::Action"
        ],
        sub_name => "_actions",
    );

    return ($self);
}

=head2 qualify ACTIONNAME

Returns the fully qualified package name for the given provided
action.  If the C<ACTIONNAME> starts with C<Jifty::Action> or your
application's C<ActionBasePath>, simply returns the given name;
otherwise, it prefixes it with the C<ActionBasePath>.

=cut

sub qualify {
    my $self   = shift;
    my $action = shift;

    my $base_path = Jifty->config->framework('ActionBasePath');

    return $action
        if $action =~ /^Jifty::Action/
        or $action =~ /^\Q$base_path\E/;

    return $base_path . "::" . $action;
}

=head2 reset

Resets which actions are allowed to the defaults; that is, all actions
from the application's C<ActionBasePath>, and
L<Jifty::Action::Autocomplete> and L<Jifty::Action::Redirect> are
allowed; everything else is denied.  See L</restrict> for the details
of how limits are processed.

=cut

sub reset {
    my $self = shift;

    # Set up defaults
    my $app_actions = Jifty->config->framework('ActionBasePath');

    $self->action_limits(
        [   { deny => 1, restriction => qr/.*/ },
            {   allow       => 1,
                restriction => qr/^\Q$app_actions\E/,
            },
            { allow => 1, restriction => 'Jifty::Action::Autocomplete' },
            { allow => 1, restriction => 'Jifty::Action::Redirect' },
        ]
    );
}

=head2 allow RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_allowed>.  See
L</restrict> for the details of how limits are processed.

=cut

sub allow {
    my $self = shift;
    $self->restrict( allow => @_ );
}

=head2 deny RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_allowed>.  See
L</restrict> for the details of how limits are processed.

=cut

sub deny {
    my $self = shift;
    $self->restrict( deny => @_ );
}

=head2 restrict POLARITY RESTRICTIONS

Method that L</allow> and and L</deny> call internally; I<POLARITY> is
either C<allow> or C<deny>.  Allow and deny limits are evaluated in
the order they're called.  The last limit that applies will be the one
which takes effect.  Regexes are matched against the class; strings
are fully L</qualify|qualified> and used as an exact match against the
class name.  The base set of restrictions (which is reset every
request) is set in L</reset>, and usually modified by the
application's L<Jifty::Dispatcher> if need be.

If you call:

    Jifty->api->deny  ( qr'Foo' );
    Jifty->api->allow ( qr'FooBar' );
    Jifty->api->deny  ( qr'FooBarDeleteTheWorld' );

..then:

    calls to MyApp::Action::Baz will succeed.
    calls to MyApp::Action::Foo will fail.
    calls to MyApp::Action::FooBar will pass.
    calls to MyApp::Action::TrueFoo will fail.
    calls to MyApp::Action::TrueFooBar will pass.
    calls to MyApp::Action::TrueFooBarDeleteTheWorld will fail.
    calls to MyApp::Action::FooBarDeleteTheWorld will fail.

=cut

sub restrict {
    my $self         = shift;
    my $polarity     = shift;
    my @restrictions = @_;

    die "Polarity must be 'allow' or 'deny'"
        unless $polarity eq "allow"
        or $polarity     eq "deny";

    for my $restriction (@restrictions) {

        # Don't let the user "allow .*"
        die "For security reasons, Jifty won't let you allow all actions"
            if $polarity eq "allow"
            and ref $restriction
            and $restriction =~ /^\(\?[-xism]*:\^?\.\*\$?\)$/;

        # Fully qualify it if it's a string
        $restriction = $self->qualify($restriction)
            unless ref $restriction;

        # Add to list of restrictions
        push @{ $self->action_limits },
            { $polarity => 1, restriction => $restriction };
    }
}

=head2 is_allowed CLASS

Returns false if the I<CLASS> name (which is fully qualified with the
application's ActionBasePath if it is not already) is allowed to be
executed.  See L</restrict> above for the rules that the class
name must pass.

=cut

sub is_allowed {
    my $self  = shift;
    my $class = shift;

    # Qualify the action
    $class = $self->qualify($class);

    # Assume that it doesn't pass; however, the real fallbacks are
    # controlled by L</reset>, above.
    my $allow = 0;

    # Walk all of the limits
    for my $limit ( @{ $self->action_limits } ) {

        # Regexes are =~ matches, strigns are eq matches
        if ( ( ref $limit->{restriction} and $class =~ $limit->{restriction} )
            or ( $class eq $limit->{restriction} ) )
        {

            # If the restriction passes, set the current allow/deny
            # bit according to if this was a positive or negative
            # limit
            $allow = $limit->{allow} ? 1 : 0;
        }
    }
    return $allow;
}

=head2 actions

Lists the class names of all of the allowed actions for this Jifty
application.

=cut

sub actions {
    my $self = shift;
    return sort grep { $self->is_allowed($_) } $self->_actions;
}

1;
