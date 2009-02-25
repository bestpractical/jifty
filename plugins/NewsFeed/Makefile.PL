use inc::Module::Install 0.46;
name('Jifty-Plugin-NewsFeed');
version_from('lib/Jifty/Plugin/NewsFeed.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
