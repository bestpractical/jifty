use inc::Module::Install 0.46;
name('Jifty-Plugin-CodePress');
version_from('lib/Jifty/Plugin/CodePress.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
