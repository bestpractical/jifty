use inc::Module::Install 0.46;
name('Authentication-CAS');
#version_from('lib/Jifty/Plugin/Authentication/CAS.pm');
version_from('../../lib/Jifty.pm');

requires('Authen::CAS::Client');

&auto_install();

WriteAll;
