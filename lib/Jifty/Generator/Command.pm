package Jifty::Generator::Command;
use base 'App::CLI::Command';


sub status { my $self = shift;
my $msg = shift;

print $msg."\n";
}

1;
