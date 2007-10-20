#!/usr/bin/env perl
package ShrinkURL::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

# visiting / will let users create new shrunken URLs
on '/' => show 'shrink';

# any other URL is potentially a shrunken URL
on '*' => run {
    my $url = $1;

    my $shrunkenurl = ShrinkURL::Model::ShrunkenURL->new;
    $shrunkenurl->load_by_shrunken($url);

    if ($shrunkenurl->id) {
        redirect($shrunkenurl->url);
    }

    # if there's no valid URL, just let the person create a new one :)
    redirect('/');
};

1;

