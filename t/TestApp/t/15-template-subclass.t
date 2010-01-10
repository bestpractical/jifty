#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist;
use Jifty::Test::WWW::Mechanize;

my @tests = (
    {
        url  => "/entry.html",
        text => '/entry.html=TestApp::View',
    },
    {
        url  => "/base/list_s",
        text => '/base/list=TestApp::View::base'.
		'/base/view=TestApp::View::base'.
		'/base/view=TestApp::View::base'
    },
    {
        url  => "/base/list_ht",
        text => '/base/list=TestApp::View::base'.
		'/base/view=TestApp::View::base'.
		'/base/view=TestApp::View::base'
    },
    {
        url  => "/base/list_rg",
        text => '/base/list=TestApp::View::base'.
                in_region('view-0', '/base/view', '/base/view=TestApp::View::base').
                in_region('view-1', '/base/view', '/base/view=TestApp::View::base')
    },


    # instance
    {
        url  => "/instance/list_s",
        text => '/base/list=TestApp::View::instance'.
		'/instance/view=TestApp::View::instance'.
		'/instance/view=TestApp::View::instance'
    },
    {
        url  => "/instance/list_ht",
        text => '/base/list=TestApp::View::instance'.
		'/instance/view=TestApp::View::instance'.
		'/instance/view=TestApp::View::instance'
    },
    {
        url  => "/instance/list_rg",
        text => '/base/list=TestApp::View::instance'.
                in_region('view-0', '/instance/view', '/instance/view=TestApp::View::instance').
                in_region('view-1', '/instance/view', '/instance/view=TestApp::View::instance')
    },


);

sub in_region {
    qq|<script type="text/javascript">
new Region('$_[0]',{},'$_[1]',null,null);
</script><div id="region-$_[0]" class="jifty-region">$_[2]</div>|;
}

plan tests => 2 + scalar(@tests) * 2;

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::TestServer' );
my $URL = $server->started_ok;


my $mech = Jifty::Test::WWW::Mechanize->new;
foreach my $test (@tests) {
    $mech->get_ok( $URL . $test->{url}, "get '$URL: /jifty/jifty/trunk/t/TestApp/t/15-template-subclass.t $test->{url}'" );

    $mech->content_contains( $test->{text}, "found content '$test->{text}'" );
}

1;
