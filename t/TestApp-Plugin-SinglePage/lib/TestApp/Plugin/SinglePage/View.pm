package TestApp::Plugin::SinglePage::View;
use strict;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;


template '/index.html' =>
    page { title => 'test' }
    content {
        with (submit_to => '/page2'),
        form {
            select { { name is 'foo' };
                    option { { value is $_ }; $_ } for 1..10;
                };
            form_submit( label => 'Next' );
        };
        render_region('random');

        hyperlink( 
            url => '/xxx', 
            escape_label => 0, 
            label => 'Link Test',
        );

        hr { };

        hyperlink( 
            url => '/xxx', 
            escape_label => 0, 
            label => 'Link Test with parameters',
            parameters => { id => 3 },
        );

        hr { };

        hyperlink( 
            label => 'foo', 
            onclick => { 
                region => 'foo', 
                replace_with => '_r_foo', 
                args => { foo => '123123' } } 
        );

};

template '/page2' =>
    page { title => 'page2' }
    content {
    my $foo = get('foo');
    my $create = Jifty->web->new_action( class => 'CreateUser', moniker => 'create_user',
                            arguments => { name => $foo });
    my $redir = new_action(class     => "Jifty::Action::Redirect",
                    arguments => { url => '/index.html' });
    render_region( 'foo' );
    hyperlink( label => 'foo', onclick => { region => 'foo', replace_with => '_r_foo', args => { foo => '123123' } } );

    form {
        Jifty->web->form->register_action($redir);
        render_action($create);
        form_submit( label   => 'Next' );
    }
};

template 'page3' =>
    page { title => 'page3' }
    content {
    h1 { 'yatta' };
    form {
        hyperlink(label => 'Back', url => '/');
    }
};

template '_r_foo' => sub {
    my $foo = get('foo');
    h1 { $foo };
};

template '/p/history/one' => page {
    p { "This Is Page One" };
};

template '/p/history/two' => page {
    p { "This Is Page Two" };
};


template '/p/history/three' => page {
    p { "This Is Page Three" };
};


template '/xxx' => page {
    h2 { "xxx" };
    h2 { get('id') };
};

1;

