use inc::Module::Install 0.46;
name('Jifty-Plugin-TabView');

requires('URI' => 1.31);

install_share;

&auto_install();

WriteAll;
