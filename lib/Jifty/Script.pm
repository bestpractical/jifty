package Jifty::Script;
use base qw/App::CLI App::CLI::Command/;
use Jifty::Script::Command;
use Jifty::I18N;

sub prepare {
    my $self = shift;
    if ($ARGV[0] =~ /--?h(elp?)/i) {
            shift @ARGV; #discard the --help
            require Jifty::Script::Help;
            return('Jifty::Script::Help');
    }
    else {
     return $self->SUPER::prepare(@_);
 }
}

sub alias {
    return (
            server  => "StandaloneServer",
            fastcgi => "FastCGI",
           )
}




1;
