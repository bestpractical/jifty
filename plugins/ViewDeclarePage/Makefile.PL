use inc::Module::Install 0.46;

name        'Jifty-Plugin-ViewDeclarePage';
all_from    'lib/Jifty/Plugin/ViewDeclarePage.pm';

tests(join ' ', qw(t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t));

WriteAll();
