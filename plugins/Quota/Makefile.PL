use inc::Module::Install 0.46;
name('Jifty-Plugin-Quota');
version_from('lib/Jifty/Plugin/Quota.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
