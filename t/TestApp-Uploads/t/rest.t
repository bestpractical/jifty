#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 7;
use Jifty::Test::WWW::Mechanize;
use HTTP::Request::Common;

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');
my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new;

ok(1, "Loaded the test script");

# we can't use $0 because Jifty::Test::Dist can chdir and
# $0 doesn't track that
$mech->request(POST "$URL/=/action/AttachmentDetails.yml",
    Content_Type => 'multipart/form-data',
    Content => [
        content => ['t/upload.txt', 't/upload.txt',],
    ],
);
my $results = Jifty::YAML::Load($mech->content);
ok($results->{success}, 'success');
is_deeply(
    $results->{content}{contents},
    [
        {
            content_type => 'text/plain',
            filename     => 'upload.txt',
            length       => 6,
            scalar_ref   => 'upload.txt',
            stringify    => 'upload.txt',
        }
    ],
    'one attachment is parsed',
);

$mech->request(POST "$URL/=/action/AttachmentDetails.yml",
    Content_Type => 'multipart/form-data',
    Content => [
        content => ['t/upload.txt', 't/upload.txt',],
        content => ['t/upload2.txt', 't/upload2.txt'],
    ],
);
$results = Jifty::YAML::Load($mech->content);
ok($results->{success}, 'success');
is_deeply(
    $results->{content}{contents},
    [
        {
            content_type => 'text/plain',
            filename     => 'upload.txt',
            length       => 6,
            scalar_ref   => 'upload.txt',
            stringify    => 'upload.txt',
        },
        {
            content_type => 'text/plain',
            filename     => 'upload2.txt',
            length       => 11,
            scalar_ref   => 'upload2.txt',
            stringify    => 'upload2.txt',
        },
    ],
    'two attachments are parsed',
);
