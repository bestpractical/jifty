use inc::Module::Install;
name('Jifty-Plugin-EmailErrors');
version('0.01');
requires('Jifty' => '0.60507');
&auto_install();

install_share;

WriteAll;
