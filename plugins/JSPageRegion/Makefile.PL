use inc::Module::Install 0.46;
name('Jifty-Plugin-JSPageRegion');
version_from('lib/Jifty/Plugin/JSPageRegion.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
