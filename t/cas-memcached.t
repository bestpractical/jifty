use strict;
use warnings;

use Test::More;
require Jifty::Test;

eval "use Cache::Memcached";
plan skip_all => "Cache::Memcached required for testing CAS memcache store" if $@;

require IO::Socket::INET;
# check if there's a running memcached on the default port, skip otherwise
plan skip_all => "Testing CAS memcached store requires a memcached running on the default port"
    unless IO::Socket::INET->new('127.0.0.1:11211');

# We want to do the import late since it loads up Jifty and triggers CCJS's
# early generation trying to use memcached
Jifty::Test->import(tests => 17);

my $data    = "a" x (1024*10);
my $databig = "a" x (1024*1024*2);

{
    isa_ok(Jifty::CAS->backend,  "Jifty::CAS::Store::Memcached", 'Using memcached backed store');
    my $key = Jifty::CAS->publish("test$$", 'one', $data, { content_type => 'text/plain' });
    ok $key, "Published";
    is length $key, 32, "Key is 32 chars long - an MD5 sum";
    is(Jifty::CAS->key("test$$", "one"), $key, "Matches what we get back from ->key");

    my $blob = Jifty::CAS->retrieve("test$$", $key);
    ok $blob, "retrieved value";
    isa_ok $blob, 'Jifty::CAS::Blob', 'got a blob';
    is $blob->content, $data, "content is the same";
    is_deeply $blob->metadata, { content_type => 'text/plain' }, "metadata is still good";
}

{
    my $key = Jifty::CAS->publish("test$$", "two", $databig, { content_type => 'text/plain' });
    is $key, undef, "Not published, there was an error";
    is(Jifty::CAS->key("test$$", "two"), undef, "Can't lookup a key because it isn't there");
}

{
    Jifty->config->framework('CAS')->{'MemcachedFallback'} = 1;
    my $key = Jifty::CAS->publish("test$$", "three", $databig, { content_type => 'text/plain' });
    ok $key, "Published";
    is length $key, 32, "Key is 32 chars long - an MD5 sum";
    is(Jifty::CAS->key("test$$", "three"), $key, "Matches what we get back from ->key");
    
    my $blob = Jifty::CAS->retrieve("test$$", $key);
    ok $blob, "retrieved value";
    isa_ok $blob, 'Jifty::CAS::Blob', 'got a blob';
    is $blob->content, $databig, "content is the same";
    is_deeply $blob->metadata, { content_type => 'text/plain' }, "metadata is still good";
}

# XXX TODO test serving up of CAS content

