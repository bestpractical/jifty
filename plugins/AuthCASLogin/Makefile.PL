use inc::Module::Install;
name('Jifty-Plugin-AuthCASLogin');
license('Perl');
version('0.01');
requires('Jifty' => '0.60912');
requires('Jifty::Plugin::Login');
requires('AuthCAS');

install_share;

WriteAll;
