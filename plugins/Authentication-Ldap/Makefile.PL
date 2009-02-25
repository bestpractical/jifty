use inc::Module::Install 0.46;
name('Jifty-Plugin-Authentication-Ldap');
version_from('lib/Jifty/Plugin/Authentication-Ldap.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
