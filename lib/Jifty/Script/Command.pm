package Jifty::Script::Command;
use base 'App::CLI::Command';
use Jifty::I18N;

sub status { my $self = shift;
    my $msg = shift;

print $msg."\n";
}


=head3 brief_usage ($file)

Display an one-line brief usage of the command object.  Optionally, a file
could be given to extract the usage from the POD.

=cut

sub brief_usage {
    my ($self, $file) = @_;
    open my ($podfh), '<', ($file || $self->filename) or return;
    local $/=undef;
    my $buf = <$podfh>;
    if($buf =~ /^=head1\s+NAME\s*Jifty::Script::(\w+ - .+)$/m) {
        print "   ",loc(lcfirst($1)),"\n";
    } else {
        my $cmd = $file ||$self->filename;
        $cmd =~ s/^(?:.*)\/(.*?).pm$/$1/;
        print "   ", lc($cmd), " - ",loc("undocumented")."\n";
    }
    close $podfh;
}

=head3 filename

Return the filename for the command module.

=cut

sub filename {
    my $self = shift;
    my $fname = ref($self);
    $fname =~ s{::[a-z]+}{}; # subcommand
    $fname =~ s{::}{/}g;
    $INC{"$fname.pm"}
}
1;
