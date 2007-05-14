#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 4;

use_ok('TestApp::Model::User');

# Create a superuser, which will be denied access in a bit
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, 'Found a system user');

# Associate a new rule that only names starting with bob can be created
TestApp::Model::User->add_trigger( before_access => sub {
    my ($self, $right, %args) = @_;
    return 'ignore' unless $right eq 'create';
    unless ($args{name} =~ /^bob/) {
        return 'deny';
    }
    return 'ignore';
});

# Try creating non-bob, which will be denied
my $o = TestApp::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'nonbob', email => $$, password => $$ );
ok(!$id, 'User could not be created');

# Try creating bobette, which will be allowd
($id) = $o->create( name => 'bobette', email => $$, password => $$ );
ok($id, 'User could be created');
