#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist;
use Jifty::Test::WWW::Mechanize;

my @tests = (
    {   url  => "/foo/list",
        text => q|list!
<span>1</span>
<span>2</span><script type="text/javascript">
new Region('special',{"id":3},'/foo/item',null,null);
</script><div id="region-special" class="jifty-region">
<span>3</span></div>|
    },

);

plan tests => 2 + scalar(@tests) * 2;

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;

use Test::LongString;

my $mech = Jifty::Test::WWW::Mechanize->new;
foreach my $test (@tests) {
    $mech->get_ok(
        $URL . $test->{url},
        "get '$URL: /jifty/jifty/trunk/t/TestApp/t/15-template-subclass.t $test->{url}'"
    );
    is_string( $mech->content, $test->{text}, "found the test content" );

}

1;
