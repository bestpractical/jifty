use warnings;
use strict;

package Jifty::Util;

=head1 NAME

Jifty::Util - Things that don't fit anywhere else

=head1 DESCRIPTION


=cut

use Jifty ();
use File::Spec ();
use File::ShareDir ();
use Cwd ();

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
        $JIFTY_ROOT = File::Spec->rel2abs("$vol$dir");
    }
    return ($JIFTY_ROOT);
}


=head2 share_root

Returns the 'share' directory of the installed Jifty module.  This is
currently only used to store the common Mason components, CSS, and JS
of Jifty and it's plugins.

=cut

sub share_root {
    my $self = shift;
    unless (defined $SHARE_ROOT) {
        # Try for the local version, first
        my @root = File::Spec->splitdir($self->jifty_root); # lib
        pop @root; # Jifty-version
        $SHARE_ROOT = File::Spec->catdir(@root,"share");
        undef $SHARE_ROOT unless defined $SHARE_ROOT and -d $SHARE_ROOT and -d File::Spec->catdir($SHARE_ROOT,"web");

        # If that doesn't pass inspection, try File::ShareDir::dist_dir
        $SHARE_ROOT ||= eval { File::Spec->rel2abs( File::ShareDir::dist_dir('Jifty') )};
        undef $SHARE_ROOT unless defined $SHARE_ROOT and -d $SHARE_ROOT and -d File::Spec->catdir($SHARE_ROOT,"web");
    }

    die "Can't locate Jifty share root!" unless defined $SHARE_ROOT;
    return ($SHARE_ROOT);
}

=head2 app_root

Returns the application's root path.  This is done by returning
$ENV{'JIFTY_APP_ROOT'} if it exists.  If not, Jifty tries searching
upward from the current directory, looking for a directory which
contains a C<bin/jifty>.  Failing that, it searches upward from
wherever the executable was found.

It C<die>s if it can only find C</usr> or C</usr/local> which fit
these criteria.

=cut

sub app_root {
    my $self = shift;
    my %args = @_;

    return $ENV{'JIFTY_APP_ROOT'} if ($ENV{'JIFTY_APP_ROOT'});
    return $APP_ROOT if ($APP_ROOT);
    
    my @roots;

    push( @roots, Cwd::cwd() );

    eval { Jifty::Util->require('FindBin') };
    if ( my $err = $@ ) {
        #warn $@;
    } else {
        push @roots, $FindBin::Bin;
    }

    Jifty::Util->require('ExtUtils::MM') if $^O =~ /(?:MSWin32|cygwin|os2)/;
    Jifty::Util->require('Config');
    for my $root_path (@roots) {
        my ($volume, $dirs) = File::Spec->splitpath($root_path, 'no_file');
        my @root = File::Spec->splitdir($dirs);
        while (@root) {
            my $try = File::Spec->catpath($volume, File::Spec->catdir( @root, "bin", "jifty" ), '');
            if (# XXX: Just a quick hack
                # MSWin32's 'maybe_command' sees only file extension.
                # Maybe we should check 'jifty.bat' instead on Win32,
                # if it is (or would be) provided.
                # Also, /usr/bin or /usr/local/bin should be taken from
                # %Config{bin} or %Config{scriptdir} or something like that
                # for portablility.
                # Note that to compare files in Win32 we have to ignore the case
                (-e $try or (($^O =~ /(?:MSWin32|cygwin|os2)/) and MM->maybe_command($try)))
                and lc($try) ne lc(File::Spec->catdir($Config::Config{bin}, "jifty"))
                and lc($try) ne lc(File::Spec->catdir($Config::Config{scriptdir}, "jifty")) )
            {
                return $APP_ROOT = File::Spec->catpath($volume, File::Spec->catdir(@root), '');
            }
            pop @root;
        }
    }
    warn "Can't guess application root from current path ("
        . Cwd::cwd()
        . ") or bin path ($FindBin::Bin)\n" unless $args{quiet};
    return ''; # returning undef causes tons of 'uninitialized...' warnings.
}

=head2 is_app_root PATH

Returns a boolean indicating whether the path passed in is the same path as
the app root. Useful if you're recursing up a directory tree and want to
stop when you've hit the root. It does not attempt to handle symbolic links.

=cut

sub is_app_root
{
    my $self = shift;
    my $path = shift;
    my $app_root = $self->app_root;

    my $rel = File::Spec->abs2rel( $path, $app_root );

    return $rel eq File::Spec->curdir;
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
chain as necessary. (This is what 'mkdir -p' does in your shell).

=cut

sub make_path {
    my $self = shift;
    my $whole_path = shift;
    return 1 if (-d $whole_path);
    Jifty::Util->require('File::Path');

    local $@;
    eval { File::Path::mkpath([$whole_path]) };

    if ($@) {
        Jifty->log->fatal("Unable to make path: $whole_path: $@")
    }
}

=head2 require PATH

Uses L<UNIVERSAL::require> to require the provided C<PATH>.
Additionally, logs any failures at the C<error> log level.

=cut

sub require {
    my $self = shift;
    my $module = shift;
    $self->_require( module => $module,  quiet => 0);
}

sub _require {
    my $self = shift;
    my %args = ( module => undef, quiet => undef, @_);
    my $class = $args{'module'};

    # Quick hack to silence warnings.
    # Maybe some dependencies were lost.
    unless ($class) {
        Jifty->log->error(sprintf("no class was given at %s line %d\n", (caller)[1,2]));
        return 0;
    }

    return 1 if $self->already_required($class);

    # .pm might already be there in a weird interaction in Module::Pluggable
    my $file = $class;
    $file .= ".pm"
        unless $file =~ /\.pm$/;

    $file =~ s/::/\//g;

    my $retval = eval  {CORE::require "$file"} ;
    my $error = $@;
    if (my $message = $error) { 
        $message =~ s/ at .*?\n$//;
        if ($args{'quiet'} and $message =~ /^Can't locate $file/) {
            return 0;
        }
        elsif ( $error !~ /^Can't locate $file/) {
            die $error;
        } else {
            Jifty->log->error(sprintf("$message at %s line %d\n", (caller(1))[1,2]));
            return 0;
        }
    }

    # If people forget the '1;' line in the dispatcher, don't eit them
    if ($class =~ /::Dispatcher$/ and ref $retval eq "ARRAY") {
        Jifty->log->error("$class did not return a true value; assuming it was a dispatcher rule");
        Jifty::Dispatcher::_push_rule($class, $_) for @{$retval};
    }

    return 1;
}

=head2 try_to_require Module

This method works just like L</require>, except that it surpresses the error message
in cases where the module isn't found.

=cut

sub  try_to_require {
    my $self = shift;
    my $module = shift;
    $self->_require( module => $module,  quiet => 1);
}


=head2 already_required class

Helper function to test whether a given class has already been require'd.

=cut

sub already_required {
    my ($self, $class) = @_;
    $class =~ s{::}{/}g;
    return ( $INC{"$class.pm"} ? 1 : 0);
}

=head2 generate_uuid

Generate a new UUID using B<Data::UUID>.

=cut

my $Data_UUID_instance;
sub generate_uuid {
    ($Data_UUID_instance ||= do {
        require Data::UUID;
        Data::UUID->new;
    })->create_str;
}

=head2 reference_to_data Object

Provides a saner output format for models than
C<MyApp::Model::Foo=HASH(0x1800568)>.

=cut

sub reference_to_data {
    my ($self, $obj) = @_;
    (my $model = ref($obj)) =~ s/::/./g;
    my $id = $obj->id;

    # probably a file extension, from the REST rewrite
    my $extension = $ENV{HTTP_ACCEPT} =~ /^\w+$/ ? ".$ENV{HTTP_ACCEPT}" : '';

    return {
        jifty_model_reference => 1,
        id                    => $obj->id,
        model                 => $model,
        url                   => Jifty->web->url(path => "/=/model/$model/id/$id$extension"),
    };
}

=head2 stringify LIST

Takes a list of values and forces them into strings.  Right now all it does
is concatenate them to an empty string, but future versions might be more
magical.

=cut

sub stringify {
    my $self = shift;

    my @r;

    for (@_) {
        if (UNIVERSAL::isa($_, 'Jifty::Record')) {
            push @r, Jifty::Util->reference_to_data($_);
        }
        if (UNIVERSAL::isa($_, 'Jifty::DateTime') && $_->is_date) {
            push @r, $_->ymd;
        }
        elsif (defined $_) {
            push @r, '' . $_; # force stringification
        }
        else {
            push @r, undef;
        }
    }

    return wantarray ? @r : $r[-1];
}

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut

1;
