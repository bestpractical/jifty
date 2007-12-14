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
        id => 'region3',
        label => "John",
        onclick => {
            region => 'content',
            replace_with => 'hello_world',
            args => {
                name => "John"
            }
        }
    );

    hyperlink(
        id => 'region4',
        label => "Smith",
        onclick => {
            region => 'content',
            replace_with => 'hello_world',
            args => {
                name => "Smith"
            }
        }
    );

    render_region( name => 'content' );
};

template 'hello_world' => sub {
    p { "Hello, " . ( get('name') || "World" ) }
};

template 'region1' => sub {
    p { "Region One" }
};

template 'region2' => sub {
    p { "Region Two" }
};


# Templtes for testing continuation. Using the example in Jifty::Manual::Continuations
template '/c/page1' => page {
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

template '/c/page2' => page {
    form {
        label { "Second Number" };
        outs_raw('<input type="text" name="number" />');
        form_return( label => "Pick", as_button => 1);
    }
};
##
1;
