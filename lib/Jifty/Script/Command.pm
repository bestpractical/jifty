package Jifty::Script::Command;
use base 'App::CLI::Command';
use Jifty::I18N;
use Pod::Simple::Text;


=head1 NAME

Jifty::Script::Command - A base class for Jifty scripts

=head1 DESCRIPTION

An abstract base class for Jifty core scripts.


sub status { my $self = shift;
    my $msg = shift;

print $msg."\n";
}


=head3 brief_usage ($file)

Display an one-line brief usage of the command object.  Optionally, a file
could be given to extract the usage from the POD.

=cut

# XXX TODO: stolen from SVK. must refadctor back to App::CLI

sub brief_usage {
    my ($self, $file) = @_;
    open my ($podfh), '<', ($file || $self->filename) or return;
    local $/=undef;
    my $buf = <$podfh>;
    if($buf =~ /^=head1\s+NAME\s*Jifty::Script::(\w+ - .+)$/m) {
        print "   ",loc(lc($1)),"\n";
    } else {
        my $cmd = $file ||$self->filename;
        $cmd =~ s/^(?:.*)\/(.*?).pm$/$1/;
        print "   ", lc($cmd), " - ",loc("undocumented")."\n";
    }
    close $podfh;
}


=head3 usage ($want_detail)

Display usage.  If C<$want_detail> is true, the C<DESCRIPTION>
section is displayed as well.

=cut

# XXX TODO: stolen from SVK. must refadctor back to App::CLI

sub usage {
    my ($self, $want_detail) = @_;
    my $fname = $self->filename;
    my($cmd) = $fname =~ m{\W(\w+)\.pm$};
    my $parser = Pod::Simple::Text->new;
    my $buf;
    $parser->output_string(\$buf);
    $parser->parse_file($fname);

    $buf =~ s/Jifty::Script::(\w+)/\l$1/g;
    $buf =~ s/^AUTHORS.*//sm;
    $buf =~ s/^DESCRIPTION.*//sm unless $want_detail;

    my $aliases = $cmd2alias{lc $cmd} || [];
    if( @$aliases ) {
        $buf .= "ALIASES\n\n";
        $buf .= "     ";
        $buf .= join ', ', sort { $a cmp $b } @$aliases;
    }

    foreach my $line (split(/\n\n+/, $buf, -1)) {
        if (my @lines = $line =~ /^( {4}\s+.+\s*)$/mg) {
            foreach my $chunk (@lines) {
                $chunk =~ /^(\s*)(.+?)( *)(: .+?)?(\s*)$/ or next;
                my $spaces = $3;
                my $loc = $1 . loc($2 . ($4||'')) . $5;
                $loc =~ s/: /$spaces: / if $spaces;
                print $loc, "\n";
            }
            print "\n";
        }
        elsif ($line =~ /^(\s+)(\w+ - .*)$/) {
            print $1, loc($2), "\n\n";
        }
        elsif (length $line) {
            print loc($line), "\n\n";
        }
    }
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
