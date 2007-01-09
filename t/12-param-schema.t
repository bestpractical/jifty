use strict;
use warnings;

=head1 DESCRIPTION

Tests Jifty::Param::Schema

=cut

use Test::More tests => 16;

package Foo::Action::Bar;
use Jifty::Param::Schema;
use Jifty::Action schema {

param keys =>
    max_length is 30,
    label is 'Search Keys',
    hints are 'Enter your search keys here!',
    default is 'blah blah blah';
    type is 'text';

param 'keys2';

param whole_word_only =>
    type is 'checkbox',
    label is '',
    hints are 'Whole word only',
    default is 1;
};

package main;
#use YAML::Syck;

my $args = Foo::Action::Bar->arguments;
#warn Dump($args);

my $keys = $args->{keys};
ok $keys, 'keys okay';
is $keys->{length}, 30, 'max_length ok';
is $keys->{label}, 'Search Keys', 'label ok';
is $keys->{type}, 'text', 'type ok';
is $keys->{hints}, 'Enter your search keys here!', 'hints okay';
is $keys->{default_value}, 'blah blah blah', 'default_value okay';

my $keys2 = $args->{keys2};
ok $keys2, 'keys okay';
is $keys2->{label}, undef, 'label undefined';
is $keys2->{type}, 'text', 'type defaults to "text"';
is $keys2->{hints}, undef, 'hints undefined';
is $keys2->{default_value}, '', 'default_value defaults to ""';

my $word_only = $args->{whole_word_only};
ok $word_only, 'keys okay';
is $word_only->{label}, '', 'label ok';
is $word_only->{type}, 'checkbox', 'type ok';
is $word_only->{hints}, 'Whole word only', 'hints ok';
is $word_only->{default_value}, 1, 'default_value set to 1';
