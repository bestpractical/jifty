#!/usr/bin/perl -w

use Jifty::Test tests => 9;

my $web = Jifty::Test->web;
isa_ok( $web->request,  "Jifty::Request"  );
isa_ok( $web->response, "Jifty::Response" );

{
    {
        package JiftyApp::Action::Foo;
        use base 'Jifty::Action';
    }

    # Fool Jifty into thinking this is already loaded.
    local $INC{"JiftyApp/Action/Foo.pm"} = 1;

    my $action = $web->new_action( class => "Foo" );
    isa_ok( $action, "JiftyApp::Action::Foo" );
}


{
    package Jifty::Request::Subclass;
    use base qw(Jifty::Request);

    package Jifty::Response::Subclass;
    use base qw(Jifty::Response);
}


# Make sure Jifty::Test->web doesn't blow over existing requests and reponses.
Jifty->web->request (Jifty::Request::Subclass->new );
Jifty->web->response(Jifty::Response::Subclass->new);

$web = Jifty::Test->web;
isa_ok( $web->request,  "Jifty::Request::Subclass"  );
isa_ok( $web->response, "Jifty::Response::Subclass" );

# Testing new_record_action()
{
    no warnings 'redefine'; 

    # Create a mock new_action()
    $orig_new_action = \&Jifty::Web::new_action;
    *Jifty::Web::new_action = sub {
        is($args{class}, $args{expected});
    };

    Jifty->web->new_record_action(
        model         => 'Jifty::Model::ModelClass',
        expected      => 'Jifty::Action::UpdateModelClass',
    );

    Jifty->web->new_record_action(
        model         => 'Jifty::Model::ModelClass',
        record_action => 'Delete',
        expected      => 'Jifty::Action::DeleteModelClass',
    );

    Jifty->web->new_record_action(
        model         => 'TestApp::Model::Employee',
        expected      => 'TestApp::Action::UpdateEmployee',
    );

    Jifty->web->new_record_action(
        model         => 'TestApp::Model::Employee',
        record_action => 'Search',
        expected      => 'TestApp::Action::SearchEmployee',
    );

    # Restore the original
    *Jifty::Web::new_action = $orig_new_action;
}
