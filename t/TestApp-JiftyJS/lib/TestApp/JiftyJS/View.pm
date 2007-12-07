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

1;
