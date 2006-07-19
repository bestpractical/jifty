use warnings;
use strict;

package Jifty::Script::Deps;
use base qw/App::CLI::Command/;

use Config;
use File::Find::Rule;
use Module::ScanDeps;
use PAR::Dist::FromCPAN;
use Pod::Usage;
use version;
use Jifty::Config;

=head2 options

Returns a hash of all the options this script takes. (See the usage message for details)

=cut


sub options {
    return (
        "setup"             => "setup_deps",
        "help|?"            => "help",
    );
}

=head2 run

Prints a help message if the users want it. If not, goes about its
business.

Sets up the environment, checks current database state, creates or deletes
a database as necessary and then creates or updates your models' schema.

=cut

sub run {
    my $self = shift;

    Jifty->new( no_handle => 1 );

    my $root = Jifty::Util->app_root;
    chdir $root;

    # First let's find out our dependencies.
    # I think we can cache the result in META.yml or something.

    warn "Scanning for dependencies...\n";

    my @files   = _get_files_in(grep { -d } map { $_, "share/$_" } qw( lib html bin ));
    my $map     = scan_deps(
        files   => \@files,
        recurse => 1,
    );

    my @mod;
    foreach my $key (sort keys %$map) {
        my $mod = $map->{$key};
        next unless $mod->{type} eq 'module';
        next if $mod->{file} eq "$Config::Config{privlib}/$key";
        next if $mod->{file} eq "$Config::Config{archlib}/$key";
        push @mod, _name($key);

        warn "* $mod[-1]\n";
    }

    warn "Populating share/deps/...\n";

    mkdir "share";
    mkdir "share/deps";

    my $pat = '/^(?:' . join('|', map { quotemeta($_) } @mod) . ')$/';

    cpan_to_par(
        pattern => $pat,
        out     => 'share/deps/',
        follow  => 1,
        verbose => 0,
        test    => 0,
    );
}

sub _name {
    my $str = shift;
    $str =~ s!/!::!g;
    $str =~ s!.pm$!!i;
    $str =~ s!^auto::(.+)::.*!$1!;
    return $str;
}

sub _get_files_in {
  my @dirs = @_;
  my $rule = File::Find::Rule->new;
  $rule->or($rule->new
                 ->directory
                 ->name('.svn')
                 ->prune
                 ->discard,
            $rule->new
                 ->directory
                 ->name('CVS')
                 ->prune
                 ->discard,
            $rule->new
                 ->name(qr/~$/)
                 ->discard,
            $rule->new
                 ->name(qr/\.pod$/)
                 ->discard,
            $rule->new
                 ->not($rule->new->file)
                 ->discard,
            $rule->new);
  return $rule->in(grep {-e $_} @dirs);
}

1;
