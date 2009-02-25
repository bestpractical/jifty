use inc::Module::Install 0.46;
name('Jifty-Plugin-REPL');
version_from('lib/Jifty/Plugin/REPL.pm');

requires('Jifty');
requires('Devel::REPL' => 0); # Devel::REPL::Script

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
