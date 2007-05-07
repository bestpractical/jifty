package TestApp::View::instance;
use Jifty::View::Declare -base;
use base 'TestApp::View::base';

template 'myview' => sub {
    
};

template 'view' => sub {
    my $self = shift;
    outs("/instance/view=$self");
};

1;
