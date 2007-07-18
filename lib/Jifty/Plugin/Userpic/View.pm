package Jifty::Plugin::Userpic::View;

use Jifty::View::Declare -base;

template 'userpic/image' => sub {
    my ($item,$field) = get(qw(item field));
    Jifty->handler->apache->content_type("image/jpeg");
    outs_raw($item->$field());

};

1;
