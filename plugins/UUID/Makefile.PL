use inc::Module::Install 0.46;
name('Jifty-Plugin-UUID');
version_from('lib/Jifty/Plugin/UUID.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
