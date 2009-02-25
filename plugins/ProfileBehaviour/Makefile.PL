use inc::Module::Install 0.46;
name('Jifty-Plugin-ProfileBehaviour');
version_from('lib/Jifty/Plugin/ProfileBehaviour.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
