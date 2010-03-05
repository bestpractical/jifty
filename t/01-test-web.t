#!/usr/bin/perl -w

use Jifty::Test tests => 5;

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
    use Any::Moose;
    use base qw(Jifty::Request);

    package Jifty::Response::Subclass;
    use Any::Moose;
    use base qw(Jifty::Response);
}


# Make sure Jifty::Test->web doesn't blow over existing requests and reponses.
Jifty->web->request (Jifty::Request::Subclass->new );
Jifty->web->response(Jifty::Response::Subclass->new);

$web = Jifty::Test->web;
isa_ok( $web->request,  "Jifty::Request::Subclass"  );
isa_ok( $web->response, "Jifty::Response::Subclass" );
