use warnings;
use strict;

package Chat::View;
use Jifty::View::Declare -base;

template 'index.html' => page { title => "Jifty chat server" } content {
    Jifty->subs->add(
        class       => 'Message',
        mode        => 'Bottom',
        region      => "message",
        render_with => '/fragments/message'
    );
    render_region( name => "message", path => '/__jifty/empty' );
    render_region( name => "sender",  path => '/fragments/sender' );
};

template 'fragments/message' => sub {
    div { get('event')->data->{'message'} }
};


template 'fragments/sender' => sub {
    my $action = Jifty->web->new_action( class => 'Send' );
    form {
        render_param ($action => 'message', focus => 1);
        form_submit(onclick => [ { submit => $action }, { refresh_self => 1 } ]);
    }
};

1;
