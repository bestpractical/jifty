use inc::Module::Install;
name('Jifty-Plugin-AuthLDAPLogin');
license('Perl');
version('0.01');
requires('Jifty' => '0.60912');
requires('Jifty::Plugin::Login');
requires('Net::LDAP');

install_share;

WriteAll;
