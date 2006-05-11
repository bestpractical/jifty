use strict;
use warnings;

package Jifty::Plugin::EditInPlace::Dispatcher;
use Jifty::Dispatcher -base;

on qr'^/__jifty/edit/(.*?)/(.*)$', run {
    my $editor = Jifty->web->new_action(
        class     => 'Jifty::Plugin::EditInPlace::Action::FileEditor',
        moniker   => 'editpage',
        arguments => {
            source_path => $2,
            file_type   => $1,
        }
    );

    set editor => $editor;
    show '/__jifty/edit_file';
};


1;
