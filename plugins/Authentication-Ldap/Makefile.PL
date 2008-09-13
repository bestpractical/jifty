use inc::Module::Install 0.46;
name('Authentication-Ldap');
#version_from('lib/Jifty/Plugin/Authentication/CAS.pm');
version_from('../../lib/Jifty.pm');

requires('Net::LDAP');

&auto_install();

WriteAll;
