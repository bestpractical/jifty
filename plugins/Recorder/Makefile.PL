use inc::Module::Install 0.46;
name('Jifty-Plugin-Recorder');
version_from('lib/Jifty/Plugin/Recorder.pm');

requires('Jifty');
requires('Proc::ProcessTable');

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
