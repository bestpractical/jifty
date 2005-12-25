use warnings;
use strict;

package Jifty::ClassLoader;

=head1 NAME

Jifty::ClassLoader - Loads the application classes

=head1 DESCRIPTION

C<Jifty::ClassLoader> loads all of the application's model and action
classes, generating classes on the fly for Collections of pre-existing
models.

=head2 new

Returns a new ClassLoader object.  Doing this installs a hook into
C<@INC> that allows L<Jifty::ClassLoader> to dynamically create needed
classes if they do not exist already.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    push @INC, $self;
    return $self;
}

=head2 INC

The hook that is called when a module has been C<require>'d that
cannot be found on disk.  If the module is a Collection, it attempts
to generate a simple class which descends from L<Jifty::Collection>.
If it is a C<::Action::CreateFoo> or a C<::Action::UpdateFoo>, it
creates the appropriate L<Jifty::Action::Record> subclass.

=cut

sub Jifty::ClassLoader::INC {
    my ($self, $module) = @_;
    my $ApplicationClass = Jifty->framework_config('ApplicationClass');
    my $ActionBasePath = Jifty->framework_config('ActionBasePath');

    if ($module =~ m!^($ApplicationClass)(?:/|::)Model(?:/|::)([^:]+)Collection(\.pm)?$!) {
        # Auto-create Collection classes
        return undef unless $self->{models}{$ApplicationClass . "::Model::" . $2};
        
        my $content = "package ".$ApplicationClass."::Model::".$2."Collection;use base qw/Jifty::Collection/; 1;";
        open my $fh, '<', \$content;
        return $fh;


    } elsif ($module =~ m!^($ApplicationClass)(?:/|::)Action(?:/|::)(Create|Update|Delete)([^\.:]+)(\.pm)?$!) {
        # Auto-create CRUD classes
        my $modelclass = $ApplicationClass . "::Model::" . $3;
        return undef unless $self->{models}{$modelclass};

        warn "Auto-creating '$2' action for $modelclass ($module)";
        my $content = "package ".$ActionBasePath."::$2$3;"
          . "use base qw/Jifty::Action::Record::$2/;"
          . "sub record_class {'$modelclass'};"
          . "1;";
        open my $fh, '<', \$content;
        return $fh;
        
    }
    return undef;
}

=head2 require

Loads all of the application's Actions and Models.  It additionally
C<require>'s all Collections and Update/Delete actions for each Model
base class.

=cut

sub require {
    my $self = shift;
    
    my $ApplicationClass = Jifty->framework_config('ApplicationClass');
    $ApplicationClass->require;
    my $ActionBasePath = Jifty->framework_config('ActionBasePath');

    Module::Pluggable->import(
        search_path =>
          [ $ActionBasePath, map { $ApplicationClass . "::" . $_ } 'Model', 'Action', 'Notification' ],
        require => 1
    );
    $self->{models} = {map {($_ => 1)} grep {/^($ApplicationClass)::Model::([^:]+)$/ and not /Collection$/} $self->plugins};
    for my $full (keys %{$self->{models}}) {
        my($short) = $full =~ /::Model::(.*)/;
        require ($full . "Collection");
        require ($ActionBasePath . "::" . $_ . $short) for qw/Create Update/;
    }

}

1;
