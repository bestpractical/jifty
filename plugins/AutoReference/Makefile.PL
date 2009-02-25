use inc::Module::Install 0.46;
name('Jifty-Plugin-AutoReference');
version_from('lib/Jifty/Plugin/AutoReference.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
