use inc::Module::Install 0.46;
name('Jifty-Plugin-LeakTracker');
version_from('lib/Jifty/Plugin/LeakTracker.pm');

requires('Jifty');
requires('Devel::Events::Objects' => '0.02'); # Devel::Events::Handler::ObjectTracker Devel::Events::Generator::Objects
requires('Devel::Size');
requires('Proc::ProcessTable');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
