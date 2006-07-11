
=head1 NAME

Jifty::Manual::PageRegions - Using page regions

=head1 DESCRIPTION

Page regions are a way of doing the new trend of automatic in-page
replacement with JavaScript -- while at the same time providing the
same user experience for non-JavaScript enabled browsers.  Sections
are chunked into nestable "page regions," which can be refreshed
independently.

=head1 USING PAGE REGIONS

(XXX TODO Write about the glories of fragments)

=head1 GORY DETAILS

There is a bit of complication involved in making sure that the
on-server Perl implementation of page regions, and, more importantly,
how they preserve state, interacts with the client-side JavaScript
implementation.  What follows is an attempt to describe the process.

Regions, when they are created, have a default path and a default set
of arguments.  These are "defaults" because they can be overridden by
the browser -- this is what enables the browser to say "and that
region has this other path, in reality."  The same is true of
arguments; for example, a paging widget could have a default C<page>
argument of 1, but could be actually being rendered with a C<page> of
2.

These overrides are kept track of using state variables.  When a
region is entered, it peers at the currenst state variables, and
overrides the default path and arguments before rendering the region.

When a L<Jifty::Web::Form::Clickable> with an C<onclick> is
L<generated|Jifty::Web::Form::Clickable/generate>, it examines the
onclick and determines how to emulate it without JavaScript.  It
determines which actions need to be run, as well as how to manipulate
the future state variables to change the display of the appropriate
regions.  It encodes all of this in the button or link; since the
JavaScript usually returns false, the fallback mode is never seen by
the browser.

When a region is output, it is output with a tiny "region wrapper",
which serves two purposes: to inform the JavaScript of the existance
of the page region and its default path and variables, and to create a
unique C<< <div> >> for the fragment to reside in.  The browser reads
the JavaScript and creates, client-side, a model of the nested
PageRegions.  This allows the JavaScript to model the state variable
changes correctly.

When the JavaScript Update function is called, it is passed a list of
fragments that needs to be updated, as well as a list of actions that
need to be run.  As it does so, it builds up an up-to-date list of
state variables, to more closely imitate the state of a non-javascript
enabled client.  It constructs a JSON request based on that
information, and passes it off to the XML webservice endpoint on the
server.

When the request comes back, it parses the XML.  For each fragment
that was requested, it finds the correct bit of the response, and
replaces the content of the DOM with the response.  As it does so, it
re-updates the clientside view of the fragments with the server's
information -- this is particularly key for dealing with parameters
which were mapped by the request mapper.  Finally, it displays
any messages and errors from actions.

=cut
