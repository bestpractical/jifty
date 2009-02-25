use inc::Module::Install 0.46;
name('Jifty-Plugin-Authentication-CAS');
version_from('lib/Jifty/Plugin/Authentication-CAS.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
