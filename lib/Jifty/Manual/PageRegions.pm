
=head1 NAME

Jifty::Manual::PageRegions - Using page regions

=head1 DESCRIPTION

Page regions are a way of doing the new trend of automatic in-page
replacement with JavaScript -- while at the same time providing the
same user experience for non-JavaScript enabled browsers.  Sections
are chunked into nestable "page regions", which can be refreshed
independently.

=head1 USING PAGE REGIONS

=head2 Constructing Page Regions

From inside any template, a region may get constructed something like
this:

    <% Jifty->web->region( name     => 'regionname',
                           path     => '/path/of/component',
                           defaults => {argname => 'some value', ...},
                         ) %>

This call will pass all arguments to the C<new> constructor of
L<Jifty::Web::PageRegion>. The most often used parameters are:

=over

=item name

The mandatory region's name given here is used to embed the region's
content into a C<< <div> >> tag which is marked with a fully qualified
name for that region. The qualified name represents the nesting
structure of regions inside a page and is automatically built inside.

=item path (optional)

If a path is given, the component's rendered result under this path is
embedded inside the region. If no path is given, C</__jifty/empty>
will be used resulting in an empty region inside.

=item defaults (optional)

Every argument given here (as a hash-ref) will be transported to the
component that displays the region inside. The values are accessible
by building a C<< <%args> >> block in the component (Mason template)
specifying the arguments.

=back

=head2 Using Page Regions

Given a template with regions, any region can influence itself or any
other region it knows about. Doing this is typically done with
JavaScript handlers like C<onclick>. The examples below will
demonstrate some typical scenarios:

    %# replace this region with some other component
    <% Jifty->web->link( label   => 'click me',
                         onclick => {
                             replace_with => '/new/path/component',
                             args         => { argname => 'some value' },
                                    },
                       ) %>

    %# insert a new region in front of a given region
    %# use an HTML-entity as the link-text and a CSS class
    <% Jifty->web->link( label        => '%#9997;',
                         escape_label => 0,
                         class        => 'blue_button',
                         onclick => {
                             region  => 'regionname',
                             prepend => '/new/path/component',
                             args    => { argname => 'some value' },
                                    },
                       ) %>

    %# insert a new region after a given CSS selector inside $region
    <% Jifty->web->link( label   => 'add something',
                         onclick => {
                             element => $region->parent->get_element('div.list'),
                             append  => '/new/path/component',
                             args    => { argname => 'some value' },
                                    },
                       ) %>

    %# a button to replace the current region with empty content
    <% Jifty->web->link( label   => 'clear',
                         onclick => {
                             refresh_self => 1,
                             toggle       => 1,
                                    },
                         as_button => 1,
                       ) %>

    %# a button to delete some region with JavaScript confirmation alert
    <% Jifty->web->link( label   => 'delete',
                         onclick => {
                             delete  => 'regionname',
                             confirm => 'really delete this?',
                                    },
                         as_button => 1,
                       ) %>

=head1 GORY DETAILS

There is a bit of complication involved in making sure that the
on-server Perl implementation of page regions, and, more importantly,
how they preserve state, interacts with the client-side JavaScript
implementation.  What follows is an attempt to describe the process.

Regions, when they are created, have a default path and a default set
of arguments.  These are "defaults" because they can be overridden by
the browser -- this is what enables the browser to say "and that
region has this other path, in reality."  The same is true for
arguments; for example, a paging widget could have a default C<page>
argument of 1, but could be actually being rendered with a C<page> of
2.

These overrides are kept track of using state variables.  When a
region is entered, it peers at the current state variables, and
overrides the default path and arguments before rendering the region.

When a L<Jifty::Web::Form::Clickable> with an C<onclick> is
L<generated|Jifty::Web::Form::Clickable/generate>, it examines the
C<onclick> and determines how to emulate it without JavaScript.  It
determines which actions need to be run, as well as how to manipulate
the future state variables to change the display of the appropriate
regions.  It encodes all of this in the button or link; since the
JavaScript usually returns false, the fallback mode is never seen by
the browser.

When a region is output, it is output with a tiny "region wrapper",
which serves two purposes: to inform the JavaScript of the existance
of the page region and its default path and variables, and to create a
unique C<< <div> >> for the fragment to reside in.  The browser reads
the JavaScript and creates, on client-side, a model of the nested
PageRegions.  This allows the JavaScript to model the state variable
changes correctly.

When the JavaScript Update function is called, it is passed a list of
fragments that needs to be updated, as well as a list of actions that
need to be run.  As it does so, it builds up an up-to-date list of
state variables, to more closely imitate the state of a non-javascript
enabled client.  It constructs a JSON request based on that
information, and passes it off to the XML web-service endpoint on the
server.

When the request comes back, it parses the XML.  For each fragment
that was requested, it finds the correct bit of the response, and
replaces the content of the DOM with the response.  As it does so, it
re-updates the client-side view of the fragments with the server's
information -- this is particularly key for dealing with parameters
which were mapped by the request mapper.  Finally, it displays
any messages and errors from actions.

=cut
