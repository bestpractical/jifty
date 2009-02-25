use inc::Module::Install 0.46;
name('Jifty-Plugin-Feedback');
version_from('lib/Jifty/Plugin/Feedback.pm');

requires('Jifty');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
