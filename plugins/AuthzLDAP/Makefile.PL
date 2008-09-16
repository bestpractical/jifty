use inc::Module::Install;

name           'Jifty-Plugin-AuthzLDAP';
all_from       'lib/Jifty/Plugin/AuthzLDAP.pm';

version_from('../../lib/Jifty.pm');

build_requires 'Test::More';
requires('Net::LDAP');
requires('Cache::MemoryCache');

install_share;

tests('t/*.t');
auto_install;
WriteAll;

