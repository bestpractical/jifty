use inc::Module::Install;
name('Jifty-Plugin-AuthLDAPOnly');
license('Perl');
version('0.01');
requires('Jifty' => '0.60912');
requires('Scalar::Defer');
requires('Net::LDAP');

install_share;

WriteAll;
