package Jifty::Plugin::Userpic::Dispatcher;

use Jifty::Dispatcher -base;

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
