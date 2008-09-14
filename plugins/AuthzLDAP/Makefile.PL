use inc::Module::Install;

name           'Jifty-Plugin-AuthzLDAP';
all_from       'lib/Jifty/Plugin/AuthzLDAP.pm';

build_requires 'Test::More';
requires('Net::LDAP');
requires('Cache::MemoryCache');
requires('Jifty' => '0.70416');

install_share;

tests('t/*.t');
auto_install;
WriteAll;

