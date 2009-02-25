use inc::Module::Install 0.46;
name('Jifty-Plugin-Monitoring');
version_from('lib/Jifty/Plugin/Monitoring.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
