use inc::Module::Install;
name('Jifty-Plugin-Login');
version('0.01');
license('Perl');
requires('Jifty' => '0.60507');

install_share;

WriteAll;
