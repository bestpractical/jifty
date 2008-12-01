use inc::Module::Install 0.46;

name        'Jifty-Plugin-Tag';
all_from    'lib/Jifty/Plugin/Tag.pm';

tests(join ' ', qw(t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t));

WriteAll();
