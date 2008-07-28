use inc::Module::Install;
name('Jifty-Plugin-AuthCASOnly');
license('Perl');
version('0.01');
requires('Jifty' => '0.60912');
requires('AuthCAS');

install_share;

WriteAll;
