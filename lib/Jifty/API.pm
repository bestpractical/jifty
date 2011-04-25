use warnings;
use strict;

package Jifty::API;

=head1 NAME

Jifty::API - Manages and allow reflection on the Jifty::Actions that
make up a Jifty application's API

=head1 SYNOPSIS

 # Find the full name of an action
 my $class = Jifty->api->qualify('SomeAction');

 # New users cannot run some actions
 if (Jifty->web->current_user->age < 18) {
     Jifty->api->deny(qr/Vote|PurchaseTobacco/);
 }

 # Some users cannot even see some actions
 if (Jifty->web->current_user->id > 10) {
     Jifty->api->hide('Foo');
     Jifty->api->show('FooBar');
     Jifty->api->hide('FooBarDeleteTheWorld');
 }

 # Fetch the class names of all actions
 my @actions = Jifty->api->all_actions;

 # Fetch the class names of all the allowed actions
 my @allowed = Jifty->api->actions;

 # Fetch all of the visible actions (some of which may not be allowed)
 my @visible = Jifty->api->visible_actions;

 # Check to see if an action is allowed
 if (Jifty->api->is_allowed('TrueFooBar')) {
     # do something...
 }

 # Check to see if an action is visible
 if (Jifty->api->is_visible('SpamOurUsers')) {
     SpamBot->be_annoying;
 }

 # Undo all allow/deny/restrict/hide calls
 Jifty->api->reset;

=head1 DESCRIPTION

You can fetch an instance of this class by calling L<Jifty/api> in
your application. This object can be used to examine the actions
available within your application and manage access to those actions.

=cut


use base qw/Class::Accessor::Fast Jifty::Object/;


__PACKAGE__->mk_accessors(qw(action_limits));

=head1 METHODS

=head2 new

Creates a new C<Jifty::API> object.

Don't use this, see L<Jifty/api> to access a reference to
C<Jifty::API> in your application.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    # Setup the basic allow/deny rules
    $self->reset;

    # Find all the actions for the API reference (available at __actions)
    Jifty::Module::Pluggable->import(
        search_path => [
            Jifty->app_class("Action"),
            "Jifty::Action",
            map {ref($_)."::Action"} Jifty->plugins,
        ],
        except   => qr/\.#/,
        sub_name => "__actions"
    );

    return ($self);
}

=head2 qualify ACTIONNAME

Returns the fully qualified package name for the given provided
action.  If the C<ACTIONNAME> starts with C<Jifty::> or
C<ApplicationClass::Action>, simply returns the given name; otherwise,
it prefixes it with the C<ApplicationClass::Action>.

=cut

sub qualify {
    my $self   = shift;
    my $action = shift;

    # Get the application class name
    my $base_path = Jifty->config->framework('ApplicationClass');

    # Return the class now if it's already fully qualified
    return $action
        if ($action =~ /^Jifty::/
        or $action =~ /^\Q$base_path\E::/);

    # Otherwise qualify it
    return $base_path . "::Action::" . $action;
}

=head2 reset

Resets which actions are allowed to the defaults; that is, all of the
application's actions, L<Jifty::Action::AboutMe>,
L<Jifty::Action::Autocomplete>, and L<Jifty::Action::Redirect> are allowed and
visible; everything else is denied and hidden. See L</restrict> for the details
of how limits are processed.

=cut

sub reset {
    my $self = shift;

    # Set up defaults
    my $app_actions = Jifty->app_class("Action");

    # These are the default action limits
    $self->action_limits(
        [
            { deny => 1,  hide => 1, restriction => qr/.*/ },
            { allow => 1, show => 1, restriction => qr/^\Q$app_actions\E/ },
            { deny => 1,  hide => 1, restriction => qr/^\Q$app_actions\E::Record::(Create|Delete|Execute|Search|Update)$/ },
            { allow => 1, show => 1, restriction => 'Jifty::Action::AboutMe' },
            { allow => 1, show => 1, restriction => 'Jifty::Action::Autocomplete' },
            { allow => 1, show => 1, restriction => 'Jifty::Action::Redirect' },
        ]
    );
}

=head2 deny_for_get

Denies all actions except L<Jifty::Action::AboutMe>,
L<Jifty::Action::Autocomplete> and L<Jifty::Action::Redirect>. This is to
protect against a common cross-site scripting hole. In your C<before>
dispatcher rules, you can whitelist actions that are known to be read-only.

This is called automatically during any C<GET> request.

=cut

sub deny_for_get {
    my $self = shift;
    $self->deny(qr/.*/);
    $self->allow("Jifty::Action::AboutMe");
    $self->allow("Jifty::Action::Autocomplete");
    $self->allow("Jifty::Action::Redirect");
}

=head2 allow RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_allowed>.  See
L</restrict> for the details of how limits are processed.

Allowing actions also L</show> them.

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

=head2 hide RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_visible>.  See
L</restrict> for the details of how limits are processed.

Hiding actions also L</deny> them.

=cut

sub hide {
    my $self = shift;
    $self->restrict( hide => @_ );
}

=head2 show RESTRICTIONS

Takes a list of strings or regular expressions, and adds them in order
to the list of limits for the purposes of L</is_visible>.  See
L</restrict> for the details of how limits are processed.

=cut

sub show {
    my $self = shift;
    $self->restrict( show => @_ );
}

=head2 restrict POLARITY RESTRICTIONS

Method that L</allow>, L</deny>, L</hide>, and L</show> call internally;
I<POLARITY> is one of C<allow>, C<deny>, C<hide>, or C<show>. Limits are
evaluated in the order they're called. The last limit that applies will be the
one which takes effect. Regexes are matched against the class; strings are
fully L</qualify|qualified> and used as an exact match against the class name.
The base set of restrictions (which is reset every request) is set in
L</reset>, and usually modified by the application's L<Jifty::Dispatcher> if
need be.

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

my %valid_polarity = map { $_ => 1 } qw/allow deny hide show/;

sub restrict {
    my $self         = shift;
    my $polarity     = shift;
    my @restrictions = @_;

    my(undef, $file, $line) = (caller(1));

    # Check the sanity of the polarity
    die "Polarity must be one of: " . join(', ', sort keys %valid_polarity)
        unless $valid_polarity{$polarity};

    for my $restriction (@restrictions) {

        # Don't let the user "allow .*"
        die "For security reasons, Jifty won't let you allow all actions"
            if $polarity eq "allow"
            and ref $restriction
            and 'weird_string_that_does_not_match_normally' =~ $restriction
            and '' =~ $restriction;

        # Fully qualify it if it's a string
        $restriction = $self->qualify($restriction)
            unless ref $restriction;


        if ($polarity eq 'hide') {
            # Hiding an action also denies it
            push @{ $self->action_limits },
                { deny => 1, hide => 1, restriction => $restriction, from => "$file:$line" };
        } elsif ($polarity eq 'allow') {
            # Allowing an action also shows it
            push @{ $self->action_limits },
                { allow => 1, show => 1, restriction => $restriction, from => "$file:$line" };
        } else {
            # Otherwise, add to list of restrictions unmodified
            push @{ $self->action_limits },
                { $polarity => 1, restriction => $restriction, from => "$file:$line" };
        }
    }
}

=head2 is_allowed CLASS

Returns true if the I<CLASS> name (which is fully qualified if it is
not already) is allowed to be executed.  See L</restrict> above for
the rules that the class name must pass.

=cut

sub is_allowed {
    my $self   = shift;
    my $action = shift;

    $self->decide_action_polarity($action, 'allow', 'deny');
}

=head2 is_visible CLASS

Returns true if the I<CLASS> name (which is fully qualified if it is
not already) is allowed to be seen.  See L</restrict> above for
the rules that the class name must pass.

=cut

sub is_visible {
    my $self   = shift;
    my $action = shift;

    $self->decide_action_polarity($action, 'show', 'hide');
}

=head2 decide_action_polarity CLASS, ALLOW, DENY

Returns true if the I<CLASS> name it has the ALLOW restriction, false if it has
the DENY restriction. This is a helper method used by L</is_allowed> and
L</is_visible>.

If no restrictions apply to this action, then false will be returned.

=cut

sub decide_action_polarity {
    my $self  = shift;
    my $class = shift;
    my $allow = shift;
    my $deny  = shift;

    # Qualify the action
    $class = $self->qualify($class);

    # Assume that it doesn't pass; however, the real fallbacks are
    # controlled by L</reset>, above.
    my $valid = 0;

    # Walk all of the limits
    for my $limit ( @{ $self->action_limits } ) {

        # Regexes are =~ matches, strigns are eq matches
        if ( ( ref $limit->{restriction} and $class =~ $limit->{restriction} )
            or ( $class eq $limit->{restriction} ) )
        {

            # If the restriction passes, set the current $allow/$deny
            # bit according to if this was a positive or negative
            # limit
            if ($limit->{$allow}) {
                $valid = 1;
            }
            if ($limit->{$deny}) {
                $valid = 0;
            }
        }
    }

    return $valid;
}

=head2 explain CLASS

Returns a string describing what allow, deny, show, and hide rules
apply to the class name.

=cut

sub explain {
    my $self = shift;
    my $class = shift;

    $class = $self->qualify($class);

    my $str = "";
    for my $limit ( @{$self->action_limits} ) {
        next unless $limit->{from};
        if ( ( ref $limit->{restriction} and $class =~ $limit->{restriction} )
            or ( $class eq $limit->{restriction} ) )
        {
            for my $type (qw/allow deny show hide/) {
                $str .= ucfirst($type)." at ".$limit->{from}.", matches ".$limit->{restriction}."\n"
                    if $limit->{$type};
            }
        }
    }
    return $str;
}

=head2 all_actions

Lists the class names of all actions for this Jifty application,
regardless of which are allowed or hidden.  See also L</actions> and
L</visible_actions>.

=cut

# Plugin actions under Jifty::Plugin::*::Action are mirrored under
# AppName::Action by Jifty::ClassLoader; this code makes all_actions
# reflect this mirroring.
sub all_actions {
    my $self = shift;
    unless ( $self->{all_actions} ) {
        my @actions = $self->__actions;
        my %seen;
        $seen{$_}++ for @actions;
        for (@actions) {
            if (/^Jifty::Plugin::(.*)::Action::(.*)$/) {
                my $classname = Jifty->app_class( Action => $2 );
                push @actions, $classname unless $seen{$classname};
            }
        }
        $self->{all_actions} = \@actions;
    }
    return @{ $self->{all_actions} };
}

=head2 actions

Lists the class names of all of the B<allowed> actions for this Jifty
application; this may include actions under the C<Jifty::Action::>
namespace, in addition to your application's actions.  See also
L</all_actions> and L</visible_actions>.

=cut

sub actions {
    my $self = shift;
    return sort grep { $self->is_allowed($_) } $self->all_actions;
}

=head2 visible_actions

Lists the class names of all of the B<visible> actions for this Jifty
application; this may include actions under the C<Jifty::Action::>
namespace, in addition to your application's actions.  See also
L</all_actions> and L</actions>.

=cut

sub visible_actions {
    my $self = shift;
    return sort grep { $self->is_visible($_) } $self->all_actions;
}

=head1 SEE ALSO

L<Jifty>, L<Jifty::Web>, L<Jifty::Action>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC. 
Jifty is distributed under the same terms as Perl itself.

=cut

1;
