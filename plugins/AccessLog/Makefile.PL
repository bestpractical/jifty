use inc::Module::Install 0.46;
name('Jifty-Plugin-AccessLog');
version_from('lib/Jifty/Plugin/AccessLog.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
