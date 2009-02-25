use inc::Module::Install 0.46;
name('Jifty-Plugin-ViewDeclarePage');
version_from('lib/Jifty/Plugin/ViewDeclarePage.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
