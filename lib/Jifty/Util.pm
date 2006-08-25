use warnings;
use strict;

package Jifty::Util;

=head1 NAME

Jifty::Util - Things that don't fit anywhere else

=head1 DESCRIPTION


=cut

use Jifty;
use File::Spec;
use File::Path;
use File::ShareDir;
use UNIVERSAL::require;
use ExtUtils::MakeMaker;
use Cwd ();
use Config;

# Trivial memoization to ward off evil Cwd calls.
use vars qw/%ABSOLUTE_PATH $JIFTY_ROOT $SHARE_ROOT $APP_ROOT/;


=head2 absolute_path PATH

C<absolute_path> converts PATH into an absolute path, relative to the
application's root (as determined by L</app_root>)  This can be called
as an object or class method.

=cut

sub absolute_path {
    my $self = shift;
    my $path = shift || '';


    return $ABSOLUTE_PATH{$path} if (exists $ABSOLUTE_PATH{$path});
    $path = $self->canonicalize_path($path);
    return $ABSOLUTE_PATH{$path} = File::Spec->rel2abs($path , Jifty::Util->app_root);
} 


=head2 canonicalize_path PATH

Takes a "path" style /foo/bar/baz and returns a canonicalized (but not necessarily absolute)
version of the path.  Always use C</> as the separator, even on platforms which recognizes
both C</> and C<\> as valid separators in PATH.

=cut 

sub canonicalize_path {
    my $self = shift;
    my $path = shift;

    my @path = File::Spec->splitdir($path);

    my @newpath;

    for (@path)  {
        # If we have an empty part and it's not the root, skip it.
        if ( @newpath and ($_ =~ /^(?:\.|)$/)) {
            next;
        }
        elsif( $_ ne '..')  {
        push @newpath, $_ ;
    } else {
        pop @newpath;
    }

    }

    
    return File::Spec::Unix->catdir(@newpath);


}


=head2 jifty_root

Returns the root directory that Jifty has been installed into.
Uses %INC to figure out where Jifty.pm is.

=cut

sub jifty_root {
    my $self = shift;
    unless ($JIFTY_ROOT) {
        my ($vol,$dir,$file) = File::Spec->splitpath($INC{"Jifty.pm"});
        $JIFTY_ROOT = File::Spec->rel2abs($dir);   
    }
    return ($JIFTY_ROOT);
}


=head2 share_root

Returns the 'share' directory of the installed Jifty module.  This is
currently only used to store the common Mason components.

=cut

sub share_root {
    my $self = shift;

    $SHARE_ROOT ||=  eval { File::Spec->rel2abs( File::ShareDir::module_dir('Jifty') )};
    if (not $SHARE_ROOT or not -d $SHARE_ROOT) {
        # XXX TODO: This is a bloody hack
        # Module::Install::ShareDir and File::ShareDir don't play nicely
        # together
        my @root = File::Spec->splitdir($self->jifty_root); # lib
        pop @root; # Jifty-version
        $SHARE_ROOT = File::Spec->catdir(@root,"share");
    }
    return ($SHARE_ROOT);
}

=head2 app_root

Returns the application's root path.  This is done by searching upward
from the current directory, looking for a directory which contains a
C<bin/jifty>.  Failing that, it searches upward from wherever the
executable was found.

It C<die>s if it can only find C</usr> or C</usr/local> which fit
these criteria.

=cut

sub app_root {
    my $self = shift;


    return $APP_ROOT if ($APP_ROOT);
    
    my @roots;

    push( @roots, Cwd::cwd() );

    eval { require FindBin };
    if ( my $err = $@ ) {

        #warn $@;
    } else {
        push @roots, $FindBin::Bin;
    }

    for (@roots) {
        my @root = File::Spec->splitdir($_);
        while (@root) {
            my $try = File::Spec->catdir( @root, "bin", "jifty" );
            if (    -e $try
                # XXX: Just a quick hack
                # MSWin32's 'maybe_command' sees only file extension.
                # Maybe we should check 'jifty.bat' instead on Win32,
                # if it is (or would be) provided.
                # Also, /usr/bin or /usr/local/bin should be taken from
                # %Config{bin} or %Config{scriptdir} or something like that
                # for portablility.
                and ($^O eq 'MSWin32' or -x $try or MM->maybe_command($try))
                and $try ne File::Spec->catdir($Config{bin}, "jifty")
                and $try ne File::Spec->catdir($Config{scriptdir}, "jifty") )
            {
                return $APP_ROOT = File::Spec->catdir(@root);
            }
            pop @root;
        }
    }
    warn "Can't guess application root from current path ("
        . Cwd::cwd()
        . ") or bin path ($FindBin::Bin)\n";
    return ''; # returning undef causes tons of 'uninitialized...' warnings.
}

=head2 default_app_name

Returns the default name of the application.  This is the name of the
application's root directory, as defined by L</app_root>.

=cut

sub default_app_name {
    my $self = shift;
    my @root = File::Spec->splitdir( Jifty::Util->app_root);
    my $name =  pop @root;

    # Jifty-0.10211 should become Jifty
    $name = $1 if $name =~ /^(.*?)-(.*\..*)$/;

    # But don't actually allow "Jifty" as the name
    $name = "JiftyApp" if lc $name eq "jifty";

    return $name;
}

=head2 make_path PATH

When handed a directory, creates that directory, starting as far up the 
chain as necessary. (This is what 'mkdir -p' does in your shell)

=cut

sub make_path {
    my $self = shift;
    my $whole_path = shift;
    return 1 if (-d $whole_path);
    File::Path::mkpath([$whole_path]);
}

=head2 require PATH

Uses L<UNIVERSAL::require> to require the provided C<PATH>.
Additionally, logs any failures at the C<error> log level.

=cut

sub require {
    my $self = shift;
    my $class = shift;

    # Quick hack to silence warnings.
    # Maybe some dependencies were lost.
    unless ($class) {
        Jifty->log->error(sprintf("no class was given at %s line %d\n", (caller)[1,2]));
        return 0;
    }

    return 1 if $self->already_required($class);

    my $retval = $class->require;
    if ($UNIVERSAL::require::ERROR) {
        my $error = $UNIVERSAL::require::ERROR;
        $error =~ s/ at .*?\n$//;
        Jifty->log->error(sprintf("$error at %s line %d\n", (caller)[1,2]));
        return 0;
    }

    # If people forget the '1;' line in the dispatcher, don't eit them
    if ($class =~ /::Dispatcher$/ and ref $retval eq "ARRAY") {
        Jifty->log->error("$class did not return a true value; assuming it was a dispatcher rule");
        Jifty::Dispatcher::_push_rule($class, $_) for @{$retval};
    }

    return 1;
}

=head2 already_required class

Helper function to test whether a given class has already been require'd.

=cut


sub already_required {
    my ($self, $class) = @_;
    my $path =  join('/', split(/::/,$class)).".pm";
    return ( $INC{$path} ? 1 : 0);
}

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut

1;
