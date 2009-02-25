use inc::Module::Install 0.46;
name('Jifty-Plugin-GoogleMap');
version_from('lib/Jifty/Plugin/GoogleMap.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
