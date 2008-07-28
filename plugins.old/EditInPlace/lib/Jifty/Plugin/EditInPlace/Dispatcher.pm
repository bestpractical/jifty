use strict;
use warnings;

package Jifty::Plugin::EditInPlace::Dispatcher;
use Jifty::Dispatcher -base;

before qr'^/__jifty/(edit|create)(_inline/|)/(.*?)/(.*)$', run {
    # Claim this as ours -- skip ACLs, etc
    last_rule;
};

on qr'^/__jifty/(edit|create)(_inline|)/(.*?)/(.*)$', run {
    my $editor = Jifty->web->new_action(
        class     => 'Jifty::Plugin::EditInPlace::Action::FileEditor',
        moniker   => 'editpage',
        arguments => {
            source_path => $4,
            file_type   => $3,
        }
    );

    set editor => $editor; 
    set path => $4;
    show "/__jifty/$1_file$2";
};


1;
