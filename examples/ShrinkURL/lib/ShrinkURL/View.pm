#!/usr/bin/env perl
package ShrinkURL::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template 'shrink' => page {

    # render the "shrink a URL" widget, which we can put on any page of the app
    render_region(
        name => 'new_shrink',
        path => '/misc/new_shrink',
    );

    # render an empty region that we push results onto
    render_region(
        name => 'new_shrinks',
    );
};

template '/misc/new_shrink' => sub {
    my $action = new_action(class => 'CreateShrunkenURL');
    form {
        Jifty->web->form->register_action($action);
        render_action($action => ['url']);

        form_submit(
            submit  => $action,
            label   => _('Shrink it!'),

            onclick => [
                { submit => $action },
                {
                    # prepend this result onto the empty region above
                    region => 'new_shrinks',
                    prepend => '/misc/shrunk_region',
                    args => {
                        id => { result_of => $action, name => 'id' },
                    },
                },
            ],
        );
    };
};

template '/misc/shrunk_region' => sub {
    my $id = get 'id';
    my $shrunken = ShrinkURL::Model::ShrunkenURL->new;
    $shrunken->load($id);

    if ($shrunken->id) {
        div {
            strong { a { attr { href => $shrunken->shrunken } $shrunken->shrunken  } };
            outs _(" is now a shortcut for %1.", $shrunken->url);
        }
    }
};

1;

