use inc::Module::Install 0.46;
name('Jifty-Plugin-OpenID');
version_from('lib/Jifty/Plugin/OpenID.pm');

requires('Jifty');
requires('Net::OpenID::Consumer');
requires('Cache::FileCache');
requires('LWPx::ParanoidAgent');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
