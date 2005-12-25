use warnings;
use strict;

package Jifty;

=head1 NAME

Jifty -- Just Do It

=head1 DESCRIPTION

Yet another web framework.  

=cut

use Jifty::Everything;
use UNIVERSAL::require;

use base qw/Jifty::Object/;

use vars qw/$HANDLE $CONFIG $LOGGER/;

=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new C<Jifty> object. This object deals
with configuration files, logging and database handles for the system.

=head3 Arguments

=over

=item no_handle

If this is set to true, Jifty will not connect to a database.  Only use
this if you're about to drop the database or do something extreme like
that; most of Jifty expects the handle to exist.  Defaults to false.

=back

=head3 Configuration

This method will load the main configuration file for the application
and use that to find a vendor configuration file. (If it doesn't find
a framework variable named 'VendorConfig', it will use the
C<JIFTY_VENDOR_CONFIG> environment variable.

After loading the vendor configuration file (if it exists), the
framework will look for a site configuration file, specified in either
the framework's C<SiteConfig> or the C<JIFTY_SITE_CONFIG> environment
variable.

Values in the site configuration file clobber those in the vendor
confjguration file. Values in the vendor configuration file clobber
those in the application configuration file.

=cut

sub new {
    my $ignored_class = shift;

    my %args = (
        no_handle => 0,
        logger_component => undef,
        @_
    );

    # Load the configuration. stash it in ->config  
    __PACKAGE__->config(Jifty::Config->new());

    __PACKAGE__->logger(Jifty::Logger->new($args{'logger_component'}));

    unless ($args{'no_handle'} or not Jifty->config->framework('Database') ) {

        Jifty->handle(Jifty::Handle->new());
        Jifty->handle->connect();
        Jifty->handle->check_schema_version();
    }

    my $loader = Jifty::ClassLoader->new();
    $loader->require;
}


# Getter/setter for config hash
sub config {
    my $class = shift;
    $CONFIG = shift if (@_);
    return $CONFIG;
}


=head2 logger

An accessor for our L<Log4Perl> configuration.

Not actually that interesting, as Log4Perl seems to maintain all its state
internally.

=cut

# Getter/setter for config hash
sub logger {
    my $class = shift;
    $LOGGER = shift if (@_);
    return $LOGGER;
}

=head2 handle

Get/set our L<Jifty::Handle> object

=cut

sub handle  {
    my $class = shift;
    $HANDLE = shift if (@_);
    return $HANDLE;
}


=head2 framework

Returns the current L<Jifty::Web> object.

=cut

sub web {

    $HTML::Mason::Commands::JiftyWeb ||= Jifty::Web->new();
    return $HTML::Mason::Commands::JiftyWeb;;
} 

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut

1;
