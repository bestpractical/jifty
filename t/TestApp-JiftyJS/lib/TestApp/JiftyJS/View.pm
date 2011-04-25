package TestApp::JiftyJS::View;
use Jifty::View::Declare -base;

template '/1-jifty-update.html' => page {
    h1 { "Jifty.update() tests" };

    hyperlink(
        id => 'region1',
        label => "Region 1",
        onclick => {
            region => 'content',
            replace_with => 'region1'
        }
    );

    hyperlink(
        id => 'region2',
        label => "Region 2",
        onclick => {
            region => 'content',
            replace_with => 'region2'
        }
    );

    hyperlink(
        id => 'region3', label => "John",
        onclick => {
            region => 'content',
            replace_with => 'hello_world',
            args => { name => "John" }
        }
    );

    hyperlink(
        id => 'region4', label => "Smith",
        onclick => {
            region => 'content',
            replace_with => 'hello_world',
            args => {
                name => "Smith"
            }
        }
    );

    hyperlink(
        id => 'append-region', label => "Append To Region",
        onclick => {
            region => "content",
            append => "hello_world"
        }
    );

    hyperlink(
        id => 'prepend-region', label => "Prepend To Region",
        onclick => {
            region => "content",
            prepend => "hello_world"
        }
    );

    hyperlink(
        id => 'delete-region',
        label => "Delete Region",
        onclick => {
            delete => "content"
        }
    );

    hr {};

    render_region( name => 'content' );
};

template 'hello_world' => sub {
    p {  (get('with_time') ? "Time: " . time . ". " : "")
             . "Hello, " . ( get('name') || "World" ) };
};

template 'region1' => sub {
    p { "Region One" }
};

template 'region2' => sub {
    p { "Region Two" }
};

template '/region/multiupdate' => page {
    hyperlink(
        id => 'update',
        label => "Update All",
        onclick => [
            "alert('42');",
            { region => 'content1', replace_with => 'region1' },
            { region => 'content2', replace_with => 'region2' },
            { region => 'content3', replace_with => 'hello_world', arguments => { name => "Pony" } },
        ]
    );

    for (1..3) {
        with(class=>'column'), div {
            render_region( name => "content$_" );
        }
    }
    with(style=>"clear:both;"), div {};
};

# Templtes for testing continuation. Using the example in Jifty::Manual::Continuations
private template '/c/_first_number_form' => sub {
    my $action = new_action(class => 'AddTwoNumbers');
    form {
        $action->form_field( 'first_number' )->render;
        $action->form_field( 'second_number',
                             default_value => {
                                 request_argument => "number",
                             }
                         )->render;
        tangent(
            url => '/c/page2',
            submit => $action,
            label => "Enter a second number"
        );
    };
};

template '/c/page1' => page {
    show('/c/_first_number_form');
};

template '/c/page_another_one' => page {
    show('/c/_first_number_form');
};

template '/c/page2' => page {
    form {
        label { "Second Number" };
        outs_raw('<input type="text" class="text" name="number" />');
        form_return( label => "Pick", as_button => 1);
    }
};

### tangent/reutrn test temapltes

template '/tangent/returner' => page {
    Jifty->web->return( label => "Go Back", to => "/", id => 'returner' )->render;
};

template '/tangent/page1' => page {
    tangent( label => "Go to Returner", url => "/tangent/returner", id => 'to-returner' );
};

template '/tangent/page2' => page {
    tangent( label => "Go to Returner", url => "/tangent/returner", id => 'to-returner' );
};

template '/tangent/page3' => page {
    hyperlink( label => "Go to Returner", url => "/tangent/returner", id => 'to-returner' );
};


### action field test templates

template '/act/play' => page {
    my $a = new_action(class => 'Play');
    form {
        render_action($a);
        form_submit( label => "Submit" );
    };
};

template '/effects' => page {
    h1 { "Jifty.update() tests with effects" };

    for (qw/Appear SlideDown/) {
        hyperlink(
            label => "Append ($_)",
            onclick => {
                append => 'hello_world',
                region => 'content',
                args => {
                    with_time => 1,
                    name => "Append with effect $_"
                },
                effect => $_,
                effect_args => "slow"
            }
        );
        outs_raw("&nbsp;");

        hyperlink(
            label => "Prepend ($_)",
            onclick => {
                prepend => 'hello_world',
                region => 'content',
                args => {
                    with_time => 1,
                    name => "Prepend with effect $_"
                },
                effect => $_,
                effect_args => "slow"
            }
        );

        outs_raw("&nbsp;|&nbsp;");
    }


    hyperlink(
        label => "Reset",
        onclick => {
            region => "content",
            replace_with => "hello_world"
        }
    );

    hr {};

    render_region( name => 'content', path => "hello_world" );
};

template '/act/play2' => page {
    my $action = new_action(class => 'Play2', moniker => "play2");
    form {
        render_action($action);

        form_next_page( url => "/redirected");
        form_submit( label => "Submit" );
    };
};

template '/act/play3' => page {
    my $action = new_action(moniker => "play2", class => "Play2");
    form {
        $action
            ->form_field('text',
                         label => "Hi",
                         sticky => 0,
                         placeholder => "foobar click me to enter text")
            ->render();
        form_submit( label => "Submit" );
    };
};

template '/redirected' => page {
    p { "Redirected!" }
};

template '/p/zero' => page {
    render_region("__page", path => "/p/one");
};

template '/p/one' => sub {
    p {
        outs "FooBar.";
        hyperlink(
            label => "Two",
            onclick => {
              replace_with => '/p/two'
            },
            as_button => 1
        );
    }
};

template '/p/two' => sub {
    hyperlink(
        label => "Two",
        onclick => {
            refresh_self => 1,
        },
        as_button => 1
    );
    p { "Lorem Ipsum... " } for 1..100;

    outs_raw(<<E);
    <script type="text/javascript">
    jQuery(function() {
        alert( ''+jQuery("p").size() );
    });
    </script>
E


};


1;
