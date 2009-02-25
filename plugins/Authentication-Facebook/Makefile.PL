use inc::Module::Install 0.46;
name('Jifty-Plugin-Authentication-Facebook');
version_from('lib/Jifty/Plugin/Authentication-Facebook.pm');

requires('Jifty');
requires('WWW::Facebook::API' => '0.3.6');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
