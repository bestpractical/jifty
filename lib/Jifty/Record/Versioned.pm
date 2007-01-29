use warnings;
use strict;

=head1 NAME

Jifty::Record::Versioned -- Revision-controlled database records for Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Database:
      RecordBaseClass: Jifty::Record::Versioned

=cut

package Jifty::Record::Versioned;
use Jifty::Util;
use Jifty::YAML;
use Jifty::Record;
use base 'Jifty::DBI::Record';

use SVN::Fs;
use SVN::Repos;
use SVN::Simple::Edit;
use File::Basename;
use File::Path;
use YAML::Syck 0.82;

my ($repos, $fs, $uri);

sub init_repos {
    my $self = shift;
    return ($repos, $fs, $uri) if $repos;

    my $path = Jifty::Util->absolute_path('var/repos');

    File::Path::rmtree([$path]);

    if (!-d $path) {
        Jifty::Util->make_path(dirname($path));
        $repos = SVN::Repos::create($path, undef, undef, undef,
                        {'fs-type' => $ENV{SVNFSTYPE} || 'fsfs',
                            'bdb-txn-nosync' => '1',
                            'bdb-log-autoremove' => '1'});
    }
    else {
        our $REPOSPOOL = SVN::Pool->new;
        $repos = SVN::Repos::open($path, $REPOSPOOL);
    }

    $uri = File::Spec->rel2abs( $path ) ;
    $uri =~ s{^|\\}{/}g if ($^O eq 'MSWin32');
    $uri = "file://$uri";

    print STDERR "*** Created Subversion Repository:\n    $uri\n\n";

    $fs = $repos->fs;

    return ($repos, $fs, $uri) if $repos;
}

sub new_edit {
    my $self = shift;
    my ($repos, $fs, $uri) = $self->init_repos;

    my $base = $fs->youngest_rev;
    my $edit = SVN::Simple::Edit->new(
        _editor => [
            SVN::Repos::get_commit_editor(
                $repos, $uri, '/', 'root', 'FOO', undef, # \&committed
            )
        ],
        pool => SVN::Pool->new,
        missing_handler => SVN::Simple::Edit::check_missing($fs->revision_root ($base))
    );
    $edit->open_root($base);

    return $edit;
}

sub __create {
    my ($self, %attribs) = @_;
    my $uuid = ($attribs{__uuid} ||= Jifty::Util->generate_uuid);
    my $rv = $self->SUPER::__create(%attribs);
    if ($rv) {
        # Write to SQL!
        my $edit= $self->new_edit;

        local $YAML::Syck::Headless = 1;
        local $YAML::Syck::ImplicitTyping = 1;
        local $YAML::Syck::ImplicitBinary = 1;
        local $YAML::Syck::ImplicitUnicode = 1;

        foreach my $key (sort keys %attribs) {
            next if $key eq '__uuid';
            $edit->add_file("=/$uuid/$key");
            $edit->modify_file("=/$uuid/$key", YAML::Syck::Dump($attribs{$key}));
        }

        $edit->close_edit;
    }
    return $rv;
}

sub __set {
    my $self = shift;
    return $self->SUPER::__set(@_);
}

sub __delete {
    my $self = shift;
    return $self->SUPER::__set(@_);
}

1;
