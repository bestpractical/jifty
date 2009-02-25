use inc::Module::Install 0.46;
name('Jifty-Plugin-Tag');
version_from('lib/Jifty/Plugin/Tag.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
