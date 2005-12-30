=head1 NAME

Jifty::Dispatcher

=head1 DESCRIPTION

XXX TODO HEY YOU: THIS CODE DOES NOT EXIST YET. THIS IS JUST SPECULATIVE.


C<Jifty::Dispatcher> takes requests for pages, walks through a dispatch table, possibly
running code or transforming the request before finally handing off control to the templating
system to display the page the user requested or whatever else the system has decided to 
display instead.  Generally, this is B<not> the place to be performing model and user specific 
access control checks or updating your database based on what the user has sent in. But it might be 
a good place to enable or disable specific C<Jifty::Action>s using L<Jifty::Web/allow_actions> and L<Jifty::Web/deny_actions> or to completely disallow user access to private "component" templates such as the _elements directory in a default Jifty application.  It's also the right way to enable L<Jifty::LetMe> actions.

The Dispatcher runs _before_ any actions are evaluated, but I<after> we've processed all the user's 
input.

This is smack-dab in the middle of Jifty::Web->handle_request.  

It doesn't matter whether the page the user's asked us to display exists, we're running the dispatcher.

Dispatcher directives are evaluated in order until we get to either a "render_page", "redirect" or an "abort".

Each directive's code block runs in its own scope, but shares a common C<$dispatcher> object.

=head1 EXAMPLE

package MyWeblog::Dispatcher;
use base 'Jifty::Dispatcher';

url qr|^/error/| => { render_page };
url qr|^/| => { Jifty::Web->handle_request }; # XXX TODO, DO WE WANT THIS HERE OR AT THE END?
url qr|/_elements/| => { redirect( url => '/errors/'.$dispatcher->url)  };             
url qr|^/let/(.*)$| => {

    # Because we're granting permissions on /let/... based on an auth token
    # we tighten up the ::Action::.* permissions. 

    Jifty->web->deny_actions(qr/.*/);
    Jifty->web->allow_actions(qr/Jifty::Action::Redirect/);

    $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);

    redirect('/error/let_me/invalid_token') unless ($let_me->validate);

    # This "local" current_user is never persisted to the database.
    # This will persist only for the rest of the current request.
    Jifty->web->temporary_current_user($let_me->validated_current_user);
   
    set_page($let_me->path);
    pass_arguments(%{$let_me->args});
};



=cut

=head1 Data your dispatch routines has access to

=head2 url

=head1 Things your dispatch routine might do

=head2 pass_arguments

Adds an argument to what we're passing to our template

Takes a hash of  key => value pairs.


=head2 delete_arguments

Deletes an argument we were passing to our template. Could be something we decided to pass
earlier or something the user wanted to pass in.

Takes an array of argument names.

=head2 set_page 

Sets the page that we'll render when we actually do our rendering. Takes the path to a template.

=head2 render_page 

=head2 abort

=head2 redirect

Redirect might have reason to want to be internal instead of external. not sure


=cut 

1;
