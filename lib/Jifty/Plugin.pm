use strict;
use warnings;

package Jifty::Plugin;
use base qw/Class::Accessor::Fast Jifty::Object/;
__PACKAGE__->mk_accessors('_pre_init');

=head1 NAME

Jifty::Plugin - Describes a plugin to the Jifty framework

=head1 DESCRIPTION

Plugins are like mini-apps.  They come in packages with share
directories which provide static and template files; they provide
actions; they have dispatcher rules.  To create the skeleton of a new
plugin, you can use the command:
    jifty plugin --name SomePlugin

To use a plugin in your Jifty application, find the C<Plugins:> line
in the C<config.yml> file:

      Plugins:
        - SpiffyThing: {}
        - SomePlugin:
            arguments: to
            the: constructor

The dispatcher for a plugin should live in
C<Jifty::Plugin::I<name>::Dispatcher>; it is written like any other
L<Jifty::Dispatcher>.  Plugin dispatcher rules are checked before the
application's rules; however, see L<Jifty::Dispatcher/Plugins and rule
ordering> for how to manually specify exceptions to this.

Actions and models under a plugin's namespace are automatically
discovered and made available to applications.

=cut

=head2 new

Sets up a new instance of this plugin.  This is called by L<Jifty>
after reading the configuration file, and is supplied whatever
plugin-specific settings were in the config file.  Note that because
plugins affect Mason's component roots, adding plugins during runtime
is not supported.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( { @_ });

    # Get a classloader set up
    Jifty::Util->require($class->dispatcher);

    # XXX TODO: Add .po path
    $self->init(@_);

    # XXX: If we have methods for halos, add them. Some way of detecting "are
    # we going to be using halos" would be superb. As it stands right now,
    # plugins are loaded, initialized, and prereq-examined in the order they're
    # listed in the config files. Instead, each phase should be separate.
    Jifty::Util->require("Jifty::Plugin::Halo");
    Jifty::Util->require("Jifty::View::Mason::Halo");

    if ($self->can('halo_pre_template')) {
        Jifty::Plugin::Halo->add_trigger(
            halo_pre_template => sub { $self->halo_pre_template(@_) },
        );
        Jifty::View::Mason::Halo->add_trigger(
            halo_pre_template => sub { $self->halo_pre_template(@_) },
        );
    }

    if ($self->can('halo_post_template')) {
        Jifty::Plugin::Halo->add_trigger(
            halo_post_template => sub { $self->halo_post_template(@_) },
        );
        Jifty::View::Mason::Halo->add_trigger(
            halo_post_template => sub { $self->halo_post_template(@_) },
        );
    }

    return $self;
}


=head2 init [ARGS]

Called by L</new>, this does any custom configuration that the plugin
might need.  It is passed the same parameters as L</new>, gleaned from
the configuration file.

=cut

sub init {
    1;
}

=head2 new_request

Called right before every request.  By default, does nothing.

=cut

sub new_request {
}

sub _calculate_share {
    my $self  = shift;
    my $class = ref($self);

    unless ( $self->{share} and -d $self->{share} ) {
        # If we've got a Jifty in @INC, and the plugin is core, the
        # right thing to do is to strip off lib/ and replace it with
        # share/plugins/Jifty/Plugin/Whatever/
        my $class_to_path = $class;
        $class_to_path =~ s|::|/|g;

        $self->{share} = $INC{ $class_to_path . '.pm' };
        $self->{share} =~ s{lib/+\Q$class_to_path.pm}{share/plugins/$class_to_path};
        $self->{share} = File::Spec->rel2abs( $self->{share} );
    }
    unless ( $self->{share} and -d $self->{share} ) {
        # As above, but only tack on share/, for when we have a
        # non-core plugin in @INC.  We do this before the
        # File::ShareDir, because File::ShareDir only looks at install
        # locations, and the plugin could be hand-set in @INC.
        my $class_to_path = $class;
        $class_to_path =~ s|::|/|g;

        $self->{share} = $INC{ $class_to_path . '.pm' };
        $self->{share} =~ s{lib/+\Q$class_to_path.pm}{share};
        $self->{share} = File::Spec->rel2abs( $self->{share} );
    }
    unless ( $self->{share} and -d $self->{share} ) {
        # If it's an installed non-core plugin, File::ShareDir's
        # dist_dir will find it for us
        my $dist = $class;
        $dist =~ s/::/-/g;
        local $@;
        eval { $self->{share} = File::ShareDir::dist_dir($dist) };
    }
    unless ( $self->{share} and -d $self->{share} ) {
        # We try this last, so plugins that moved out of core, but
        # were installed at when they _were_ in core, will get the
        # updated plugin

        # Core plugins live in jifty's share/plugins/Jifty/Plugin/Whatever/
        my $class_to_path = $class;
        $class_to_path =~ s|::|/|g;
        $self->{share} = Jifty::Util->share_root;
        $self->{share} .= "/plugins/" . $class_to_path;
    }
    unless ( $self->{share} and -d $self->{share} ) {
        $self->{share} = undef;
    }
    return $self->{share};
}


=head2 template_root

Returns the root of the C<HTML::Mason> template directory for this plugin

=cut

sub template_root {
    my $self = shift;
    my $dir =  $self->_calculate_share();
    return unless $dir;
    return $dir."/web/templates";
}

=head2 po_root

Returns the plugin's message catalog directory. Returns undef if it doesn't exist.

=cut

sub po_root {
    my $self = shift;
    my $dir = $self->_calculate_share();
    return unless $dir;
    return $dir."/po";
}

=head2 template_class

Returns the Template::Declare view package for this plugin

=cut

sub template_class {
    my $self = shift;
    my $class = ref($self) || $self;
    return $class.'::View';
}


=head2 static_root

Returns the root of the static directory for this plugin

=cut

sub static_root {
    my $self = shift;
    my $dir =  $self->_calculate_share();
    return unless $dir;
    return $dir."/web/static";
}

=head2 dispatcher

Returns the classname of the dispatcher class for this plugin

=cut

sub dispatcher {
    my $self = shift;
    my $class = ref($self) || $self;
    return $class."::Dispatcher";
}

=head2 prereq_plugins

Returns an array of plugin module names that this plugin depends on.

=cut

sub prereq_plugins {
    return ();
}

=head2 version

Returns the database version of the plugin. Needs to be bumped any time the database schema needs to be updated. Plugins that do not directly define any models don't need to worry about this.

=cut

sub version {
    return '0.0.1';
}

=head2 bootstrapper

Returns the name of the class that can be used to bootstrap the database models. This normally returns the plugin's class name with C<::Bootstrap> added to the end. Plugin bootstrappers can be built in exactly the same way as application bootstraps.

See L<Jifty::Bootstrap>.

=cut

sub bootstrapper {
    my $self = shift;
    my $class = ref $self;
    return $class . '::Bootstrap';
}

=head2 upgrade_class

Returns the name of the class that can be used to upgrade the database models and schema (such as adding new data, fixing default values, and renaming columns). This normally returns the plugin's class name with C<::Upgrade> added to the end. Plugin upgraders can be built in exactly the same was as application upgrade classes.

See L<Jifty::Upgrade>.

=cut

sub upgrade_class {
    my $self = shift;
    my $class = ref $self;
    return $class . '::Upgrade';
}

=head2 table_prefix

Returns a prefix that will be placed in the front of all table names for plugin models. Be default, the plugin name is converted to an identifier based upon the class name.

=cut

sub table_prefix {
    my $self = shift;
    my $class = ref $self;
    $class =~ s/\W+/_/g;
    $class .= '_';
    return lc $class;
}

=head2 wrap

Takes a PSGI-$app closure and returns the wrapped one if your plugin
wants to do something to the request handling process.  See also
L<Plack::Middleware>.

=cut

sub wrap {
    my ($self, $app) = @_;
    return $app;
}

1;
