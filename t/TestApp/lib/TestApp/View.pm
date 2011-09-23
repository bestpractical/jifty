package TestApp::View;
use warnings;
use strict;

use Jifty::View::Declare -base;

__PACKAGE__->use_mason_wrapper;

template 'say_hi' => page {
    my $a = Jifty->web->new_action( class => 'SayHi', moniker => "say_hi" );
    form {
       ### THIS is wrong / deprecated
       # $a->hidden('xxx_name','hidden');
       # render_param($a => 'xxx_name');
        render_param($a => 'xxx_name', render_as => 'hidden', default_value => 'some value');
        render_param( $a => 'greeting' );
        Jifty->web->form->submit(
            label   => _('Create'),
            onclick => [
                {   submit => {
                        action    => $a,
                        arguments => { name => 'dave' }
                    }
                }
            ]
        );

    };
};

template '/td/template-with-error' => page {
    outs('Before error');
    Jifty->web->non_existent_method;
    outs('After error');
};

template '/td/region-with-error' => sub{
    outs('Region before');
    Jifty->web->non_existent_method;
    outs('Region after');
};

template '/td/call-region-with-error' => sub {
    outs('Calling before');
    render_region( 'error', path => '/td/region-with-error' );
    outs('Calling after');
};

template 'concrete2.html' => sub {
    html {
        body {
            h1 { _( 'I have %1 concrete mixers', 2 ) };
        };
    };
};

template 'die.html' => sub {
    die "this is an error";
};

# The following templates are used to test the precedence of T::D over Mason and
# also that '/index.html' is only added to the path if the given path does not
# match.
template '/path_test/foo' => sub {
    outs('/path_test/foo - T::D');
};

template '/path_test/bar/index.html' => sub {
    outs('/path_test/bar/index.html - T::D');
};

template '/path_test/in_both' => sub {
    outs('/path_test/in_both - T::D');
};

template '/path_test/td_only' => sub {
    outs('/path_test/td_only - T::D');
};


# for testing subclasses
template 'entry.html' => sub {
    my $self = shift;
    outs("/entry.html=$self")
};

require TestApp::View::base;
require TestApp::View::instance;
alias TestApp::View::base under '/base';
alias TestApp::View::instance under '/instance';

use Jifty::View::Declare::CRUD;

foreach my $model  (Jifty->class_loader->models) {
    my $bare_model;
    if ($model =~ /^.*::(.*?)$/) {
        $bare_model = $1;
    }
    alias Jifty::View::Declare::CRUD under '/crud/'.$bare_model,  { object_type => $bare_model };

}


template userlist => page {
    form {
    render_region( "users", path => '/crud/User/list');
    };
};

template '/foo/list' => sub {
    outs('list!');
    show('/foo/item', { id => 1 } );
    show('/foo/item', { id => 2 } );
    render_region('special', path => '/foo/item', defaults => { id => 3 } );
};

template '/foo/item' => sub {
    my ($self, $args) = @_;
    span { $args->{id} }
};


template 'region-with-internal-redirect' => page {
    
    h1 { 'outer page'};

    render_region('internal', path => '/pre-redir-region');
    render_region('internal2', path => '/nonredir-region');
    

    h2 { 'still going'} ;
};


template 'nonredir-region' => sub {
    h1 { 'other region'};
};

template 'pre-redir-region' => sub {
    h1 { 'sorry. no.'};
};


template 'post-redir-region' => sub {

    h1 { 'redirected ok'};
};

template 'use_mason_wrapper' => page {
    h1 { 'In a Mason Wrapper?' };
};


template 'otherplace' => page {
    form { }
};

template 'naughty' => sub {
    print STDOUT "this is ", "bad";
};

1;
