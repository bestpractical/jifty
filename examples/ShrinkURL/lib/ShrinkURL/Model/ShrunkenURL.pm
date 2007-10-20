#!/usr/bin/env perl
package ShrinkURL::Model::ShrunkenURL;
use strict;
use warnings;
use Number::RecordLocator;
my $generator = Number::RecordLocator->new;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column url =>
        is distinct,
        is varchar(1000),
        is indexed;
};

# shrunken URL is just an encoding of ID
sub shrunken {
    my $self = shift;
    Jifty->web->url(path => $generator->encode($self->id));
}

# helper function so we can easily change the internal representation of
# shrunken URLs if we desire
sub load_by_shrunken {
    my $self = shift;
    my $shrunken = shift;
    my $id = $generator->decode($shrunken);

    return $self->load($id);
}

# prepend http:// if the scheme is not already there
sub canonicalize_url {
    my $self = shift;
    my $url = shift;

    $url = "http://$url"
        unless $url =~ m{^\w+://};

    return $url;
}

1;

