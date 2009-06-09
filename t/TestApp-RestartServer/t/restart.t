use strict;
use warnings;

use Test::More;
use File::Spec;
use Jifty::Test::WWW::Mechanize;
use FindBin qw($Bin);
use Cwd;
my $cwd;

BEGIN {
    plan skip_all => "live test doesn't work on Win32 at the moment" if $^O eq 'MSWin32';
}

plan tests => 8;

# NOTE: we don't use Jifty's test server just 
# because we want to test Jifty's real server

BEGIN {
    $cwd = Cwd::cwd();
    chdir("$Bin/..");
}
use Jifty;

my $config_path =
  File::Spec->catfile( Jifty::Util->app_root, 'etc', 'config.yml' );
local $/;
open my $fh, '<', $config_path or die $!;
my $config = <$fh>;
like( $config, qr/AdminMode: 1/, 'admin mode in config is enabled' );

my $INC =
  [ grep { defined } map { File::Spec->rel2abs($_) } grep { !ref } @INC ];
my @perl = ( $^X, map { "-I$_" } @$INC );

my $pid = fork;
die 'fork failed' unless defined $pid;

if ($pid) {
    my $URL  = 'http://localhost:12888';
    my $mech = Jifty::Test::WWW::Mechanize->new;
    sleep 5;
    $mech->get_ok($URL);
    $mech->content_like( qr/pony\.jpg/, 'we have a pony!' );
    $mech->content_like( qr/Administration mode is enabled/,
        'admin mode is enabled' );

    $config =~ s/AdminMode: 1/AdminMode: 0/;
    like( $config, qr/AdminMode: 0/, 'admin mode in config is off' );
    write_file( $config_path, $config );
    system("@perl bin/jifty server --restart");
    sleep 5;
    $mech->get_ok($URL);
    $mech->content_like( qr/pony\.jpg/, 'we still have a pony!' );
    $mech->content_unlike(
        qr/Administration mode is enabled/,
        'admin mode is gone on page, restart works!',
    );
    system("@perl bin/jifty server --stop");
    system("@perl bin/jifty schema --drop-database");
}
else {
    system("@perl bin/jifty server");
    exit 0;
}

END {
    $config =~ s/AdminMode: 0/AdminMode: 1/;
    write_file( $config_path, $config );
    chdir $cwd;
}

sub write_file {
    my $path    = shift;
    my $content = shift;
    open my $fh, '>', $path or die $!;
    print $fh $content;
    close $fh;
}
