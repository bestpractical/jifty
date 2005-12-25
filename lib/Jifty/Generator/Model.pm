package Jifty::Generator::Model;
use base 'Jifty::Generator';

sub options {
        ($_[0]->SUPER::options,
            'a|add' => 'add',
            'd|del|delete' => 'delete',
            't|table=s' => 'table' )

        }


sub run {
    my $self = shift;
    use YAML;
    die YAML::Dump $self;

}
1;

