use inc::Module::Install 0.46;
name('Jifty-Plugin-ExtJS');
version_from('lib/Jifty/Plugin/ExtJS.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
