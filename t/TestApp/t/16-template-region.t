#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test;
use Jifty::Test::WWW::Mechanize;

my @tests = (
    {
        url  => "/foo/list",
        text => 'list!<span>1</span>
<span>2</span>'.in_region('<span>3</span>'),
    },

);

sub in_region {
    qq|<script type="text/javascript">
new Region('$_[0]',{},'$_[1]',null);
</script><div id="region-$_[0]">$_[2]</div>|;
}

plan tests => 2 + scalar(@tests) * 2;

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;


my $mech = Jifty::Test::WWW::Mechanize->new;
foreach my $test (@tests) {
    $mech->get_ok( $URL . $test->{url}, "get '$URL: /jifty/jifty/trunk/t/TestApp/t/15-template-subclass.t $test->{url}'" );

    $mech->content_like(qr{$test->{text}}, "found the test content");
}

1;
