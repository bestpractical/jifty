use inc::Module::Install 0.46;
name('Jifty-Plugin-TabView');
version_from('lib/Jifty/Plugin/TabView.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
