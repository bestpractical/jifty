use warnings;
use strict;
 
package Jifty::Web::Form;

use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors(qw(actions printed_actions helpers name));

=head2 new ARGS

Creates a new L<Jifty::Web::Form>.  Arguments: 

=over
   
=item helpers

=item  name 

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, ref $class ? ref $class : $class;

    my %args = (
        name => undef,
        @_,
    );

    $self->_init(%args);
    return $self;
}

=for private _init

Reinitialize this form. 

=over

=item name

The form name

=back

=cut


sub _init {
    my $self = shift;
    my %args = (name => undef,
                @_);

    $self->actions( {} ) ;
    $self->printed_actions( {} ) ;
    $self->name($args{name});
}


=head2 actions

Returns a reference to a hash of L<Jifty::Action> objects in this form keyed by moniker.

If you want to add actions to this form, use L</add_action>

=cut

=head2 name [VALUE]

Gets or sets the HTML name given to the form element.

=cut

=head2 add_action PARAMHASH

Calls L<Jifty::Web/new_action> with the paramhash given, and adds it to
the form.

=cut

sub add_action {
    my $self = shift;
   $self->register_action(Jifty->framework->new_action(@_));
} 



=head2 register_action ACTION

Adds C<ACTION> as an action for this form. Called so that actions' form fields can register the action against the form they're being used in.

=cut


sub register_action {
    my $self = shift;
    my $action = shift;
    $self->actions->{ $action->moniker } =  $action;
    return $action;
}


=head2 has_action MONIKER

If this form has an action whose monkier is C<MONIKER>, returns it. Otherwise returns undef.


=cut

sub has_action {
    my $self    = shift;
    my $moniker = shift;
    if ( exists $self->actions->{$moniker} ) {
        return $self->actions->{$moniker};
    }
    else { return undef }

}



=head2 start

Renders the opening form tag.

=cut

sub start {
    my $self = shift;
    my $form_start = qq!<form method="post" action="$ENV{PATH_INFO}"!;
    $form_start   .= qq! name="@{[ $self->name ]}"! if defined $self->name;
    $form_start   .= qq! enctype="multipart/form-data" >\n!;
    Jifty->mason->out($form_start);
    '';
} 

=head2 submit MESSAGE, [PARAMETERS]

Renders a submit button with the text MESSAGE on it (which will be
HTML escaped).  Returns the empty string (for ease of use in
interpolation).  Any extra PARAMETERS are passed to
L<Jifty::Web::Form::Field::Button>'s constructor.

=cut

sub submit {
    my $self = shift;
    my $message = shift;
    
    my $button = Jifty::Web::Form::Field->new(type => "submit", render_as => "Button", label => $message, @_);
    Jifty->mason->out(qq{<span class="submit_button">}); 
    Jifty->mason->out($button->render_widget);
    Jifty->mason->out(qq{</span>});

    return '';
} 

=head2 end

Renders the closing form tag (including rendering errors for and
registering all of the actions, and registering view helper state.)
After doing this, it resets its internal state such that L</start> may
be called again.

=cut

sub end {
    my $self = shift;

    Jifty->mason->out( qq!<div class="hidden">\n! );

    $self->_print_registered_actions();

    $self->_preserve_request_helpers();
    $self->_preserve_state_variables();


    Jifty->mason->out( qq!</div>\n! );

    Jifty->mason->out( qq!</form>\n! );

    # Clear out all the registered actions and the name 
    $self->_init();

    '';
} 


=head2 print_action_registration MONIKER

Print out the action registration goo for this action _right now_, unless we've already done so. 

=cut


sub print_action_registration {
    my $self = shift;
    my $moniker = shift;
  

    my $action = $self->has_action($moniker);
    return unless ($action);
    return if exists $self->printed_actions->{$moniker};
     $self->printed_actions->{$moniker} = 1;

    $action->register();

}


# At the point this is called, it should only include actions we're registering that have no form fields
# and haven't been explicitly registered.
sub _print_registered_actions {
    my $self = shift;
    for my $a ( keys %{ $self->actions } ) {
        $self->print_action_registration($a);
    }
}

=for private _preserve_request_helpers

We want to serialze all Jifty::Helpers as part of the form

=cut

sub _preserve_request_helpers {
    my $self = shift;
    my %helper_args = Jifty->framework->request->helpers_as_query_args;
    for my $k (keys %helper_args) {
        Jifty->mason->out( qq!<input type="hidden" name="$k" value="$helper_args{$k}" />\n! );
    } 

}


sub _preserve_state_variables {
    my $self = shift;


    # Preserve state variables from the previous request, so
    # we can re-present them if validation fails
    foreach my $var (  Jifty->framework->request->state_variables  ) {
        Jifty->mason->out( qq{<input type="hidden" name="J:V-} 
                . $var->key
                . qq{" value="}
                . $var->value
                . qq{" />\n} );

    }
    foreach my $var ( keys %{ Jifty->framework->{state_variables} } ) {
        Jifty->mason->out( qq{<input type="hidden" name="J:NV-} 
                . $var
                . qq{" value="}
                . Jifty->framework->{'state_variables'}->{$var}
                . qq{" />\n} );
    }

}


=head2 next_page PARAMHASH

Set the page this form should go to on success.  This simply creates a
L<Jifty::Action::Redirect> action; any parameters in the C<PARAMHASH>
are passed as arguments to the L<Jifty::Action::Redirect> action.

=cut

sub next_page {
    my $self = shift;

    $self->add_action(class => "Jifty::Action::Redirect", moniker => "next_page", arguments => {@_});
}

=head2 unpost

Send a redirect back to the same page after the actions run.  This
ensures that reloading won't re-post any actions that you might have
just done.

=cut

sub unpost {
    my $self = shift;

    my $url = $ENV{REQUEST_URI};
    $url =~ s/\?.*//g;
    
    $self->next_page( url => $url );
}

1;
