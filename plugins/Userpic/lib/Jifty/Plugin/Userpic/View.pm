package Jifty::Plugin::Userpic::View;

use Jifty::View::Declare -base;


=head1 NAME

Jifty::Plugin::Userpic::View - View for the Userpic plugin

=head1 DESCRIPTION

A view package for the Userpic plugin.


=head1 TEMPLATES


=head2 userpic/image

Outputs the image stored in 'field' of 'item'. (Both of those are set by the dispatcher)

=cut

template 'userpic/image' => sub {
    my ($item,$field) = get(qw(item field));
    Jifty->handler->apache->content_type("image/jpeg");
    outs_raw($item->$field());

};

1;
