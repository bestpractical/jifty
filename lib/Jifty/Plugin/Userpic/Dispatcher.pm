use warnings;
use strict;

package Jifty::Plugin::Userpic::Dispatcher;


=head1 NAME

Jifty::Plugin::Userpic::Dispatcher

=head1 DESCRIPTION

The dispatcher for the Jifty Userpic plugin

=cut

use Jifty::Dispatcher -base;


=head1 RULES

=head2 on /=/plugin/userpic/*/#/*

When we're asked for a userpic for /recordclass/id/fieldname,  set it up and call /userpic/image.

=cut


on '/=/plugin/userpic/*/#/*' => run {
    my $class = $1;
    my $id = $2;
    my $field = $3;

    if ($class->isa('Jifty::Record')) {

        my $item = $class->new();
        $item->load($id);

        if ($item->id) {
            set item => $item;
            set field => $field;
            show '/userpic/image';
        }
    }
};

1;
