#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Tests that error pages work

=cut

use Jifty::Test::Dist tests => 1 + 2 * 29;
use Jifty::Test::WWW::Mechanize;

my $URL = Jifty::Test->make_server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

for my $path ("", "/td") {
    my $prefix = "$URL$path";
    $mech->get_ok("$prefix/template-with-error");
    $mech->warnings_like(qr/Can't locate object method "non_existent_method" via package "Jifty::Web"/);
    $mech->base_like(qr{errors/500}, "End up on error page");
    $mech->content_like(qr/something went awry/i, "Have error header");
    $mech->content_like(qr/locate object method .*?non_existent_method.*?/, "Have error itself, if in devel mode");
    $mech->content_like(qr/template-with-error/, "Have stack trace");
    $mech->content_unlike(qr/Before error/, "Don't have content from before error");
    $mech->content_unlike(qr/After error/, "Don't have content from after error");

    ok($mech->continuation, "Have a continuation");
    ok($mech->continuation->response->error, "Have an error set");
    isa_ok($mech->continuation->response->error, "HTML::Mason::Exception", "Error is a reference");

    # Region itself gets full page wrapper if it's the only request
    $mech->get_ok("$prefix/region-with-error", "Request region (no wrapper!) with error");
    $mech->warnings_like(qr/Can't locate object method "non_existent_method" via package "Jifty::Web"/);
    $mech->base_like(qr{errors/500}, "End up at error page");
    $mech->content_like(qr/something went awry/i, "Have error header");
    $mech->content_like(qr/locate object method .*?non_existent_method.*?/, "Have error itself, if in devel mode");
    $mech->content_like(qr/region-with-error/, "Have stack trace");
    $mech->content_unlike(qr/Region before/, "Don't have content from before error");
    $mech->content_unlike(qr/Region after/, "Don't have content from after error");

    # If it's a subrequest, don't nest wrappers
    $mech->get_ok("$prefix/call-region-with-error");
    $mech->warnings_like(qr/Can't locate object method "non_existent_method" via package "Jifty::Web"/);
    $mech->base_unlike(qr{errors/500}, "Doesn't redirect if only a region error");
    #$mech->content_unlike(qr/something went awry/i, "Doesn't have error header");
    #warn $mech->content;
    $mech->content_like(qr/<h2>Call stack<\/h2>/i, "Doesn't have error header");
    $mech->content_like(qr/locate object method .*?non_existent_method.*?/, "Has error itself, if in devel mode");
    $mech->content_like(qr/region-with-error/, "Have stack trace");
    $mech->content_like(qr/Calling before/, "Does have region content from before error");
    $mech->content_like(qr/Region before/, "Does have calling content from before error"); # TODO: change?
    $mech->content_unlike(qr/Region after/, "Don't have region content from after error");
    $mech->content_like(qr/Calling after/, "Does have calling content from after error");
}

1;

