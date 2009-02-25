use inc::Module::Install 0.46;
name('Jifty-Plugin-Attributes');
version_from('lib/Jifty/Plugin/Attributes.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
