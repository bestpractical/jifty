use inc::Module::Install 0.46;
name('Jifty-Plugin-Userpic');
version_from('lib/Jifty/Plugin/Userpic.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
