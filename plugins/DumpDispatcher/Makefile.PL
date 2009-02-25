use inc::Module::Install 0.46;
name('Jifty-Plugin-DumpDispatcher');
version_from('lib/Jifty/Plugin/DumpDispatcher.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
