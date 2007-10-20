#!/usr/bin/env perl
package ShrinkURL::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template 'shrink' => page {
    render_region(
        name => 'new_shrink',
        path => '/misc/new_shrink',
    );
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
                    region => 'new_shrinks',
                    prepend => '/misc/shrunk_region',
                    args => {
                        foo => "bar",
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

