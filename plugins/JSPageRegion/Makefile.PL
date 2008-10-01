use inc::Module::Install 0.46;
name('Jifty-Plugin-JSPageRegion');
version_from('lib/Jifty/Plugin/JSPageRegion.pm');

requires('PadWalker');

install_share;

&auto_install();

WriteAll;
