use strict;
use warnings;

use Jifty::Test;

eval "use Cache::Memcached";
plan skip_all => "Cache::Memcached required for testing CAS memcache store" if $@;

require IO::Socket::INET;
# check if there's a running memcached on the default port, skip otherwise
plan skip_all => "Testing CAS memcached store requires a memcached running on the default port"
    unless IO::Socket::INET->new('127.0.0.1:11211');

plan tests => 23;

my $data    = "a" x (1024*10);
my $databig = "a" x (1024*1024*2);

{
    ok((grep { $_ eq 'Jifty::CAS::Store::Memcached' } @Jifty::CAS::ISA), 'Using memcached backed store');
    my $key = Jifty::CAS->publish("test$$", 'one', $data, { deflate => 1, content_type => 'text/plain' });
    ok $key, "Published";
    is length $key, 32, "Key is 32 chars long - an MD5 sum";
    is(Jifty::CAS->key("test$$", "one"), $key, "Matches what we get back from ->key");
    
    my $blob = Jifty::CAS->retrieve("test$$", $key);
    ok $blob, "retrieved value";
    isa_ok $blob, 'Jifty::CAS::Blob', 'got a blob';
    is $blob->content, $data, "content is the same";
    is_deeply $blob->metadata, { deflate => 1, content_type => 'text/plain' }, "metadata is still good";
    is $blob->{content_deflated}, undef, "no deflated content until we request it";
    ok $blob->content_deflated, "got deflated content";
    ok $blob->{content_deflated}, "now deflated content exists";
}

{
    my $key = Jifty::CAS->publish("test$$", "two", $databig, { deflate => 1, content_type => 'text/plain' });
    is $key, undef, "Not published, there was an error";
    is(Jifty::CAS->key("test$$", "two"), undef, "Can't lookup a key because it isn't there");
}

{
    Jifty->config->framework('CAS')->{'MemcachedFallback'} = 1;
    my $key = Jifty::CAS->publish("test$$", "three", $databig, { deflate => 1, content_type => 'text/plain' });
    ok $key, "Published";
    is length $key, 32, "Key is 32 chars long - an MD5 sum";
    is(Jifty::CAS->key("test$$", "three"), $key, "Matches what we get back from ->key");
    
    my $blob = Jifty::CAS->retrieve("test$$", $key);
    ok $blob, "retrieved value";
    isa_ok $blob, 'Jifty::CAS::Blob', 'got a blob';
    is $blob->content, $databig, "content is the same";
    is_deeply $blob->metadata, { deflate => 1, content_type => 'text/plain' }, "metadata is still good";
    is $blob->{content_deflated}, undef, "no deflated content until we request it";
    ok $blob->content_deflated, "got deflated content";
    ok $blob->{content_deflated}, "now deflated content exists";
}

# XXX TODO test serving up of CAS content

