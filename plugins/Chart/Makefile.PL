use inc::Module::Install 0.46;
name('Jifty-Plugin-Chart');
version_from('lib/Jifty/Plugin/Chart.pm');

requires('Jifty');
requires('Chart::Base');
requires('GD');          # for a testing hack
requires('GD::Graph');
requires('XML::Simple');
requires('Image::Info'); # for testing

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
