use inc::Module::Install 0.46;
name('Jifty-Plugin-TabView');
version_from('lib/Jifty/Plugin/TabView/View.pm');

requires('URI' => 1.31);

&auto_install();

WriteAll;
