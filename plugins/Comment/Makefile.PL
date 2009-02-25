use inc::Module::Install 0.46;
name('Jifty-Plugin-Comment');
version_from('lib/Jifty/Plugin/Comment.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
