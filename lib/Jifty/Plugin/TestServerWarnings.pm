use strict;
use warnings;

package Jifty::Plugin::TestServerWarnings;
use base qw/Jifty::Plugin/;

use LWP::Simple qw//;
use Jifty::Plugin::TestServerWarnings::Appender;
use Log::Log4perl::Level;

__PACKAGE__->mk_accessors(qw(clear_screen));

=head1 NAME

Jifty::Plugin::TestServerWarnings - Stores server warnings away for later fetching

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - TestServerWarnings:
        clear_screen: 1

=head1 DESCRIPTION

This plugin add a new appender L<Jifty::Plugin::TestServerWarnings::Appender>
on the first request it sees, which stores away all messages it receives. 

It also removes the default "Screen" appender unless C<clear_screen> in the
plugin config is false or the environment variable C<TEST_VERBOSE> is true.

The warnings can be retrieved by a client-side process by calling 
L</decoded_warnings> with a base URI to the server.

This plugin is automatically added for all Jifty tests.

=head1 METHODS

=head2 init

Store the C<clear_screen> setting if it's set in the plugin config.  If it's
not set in the config, default to true unless the environment variable
C<TEST_VERBOSE> is true.

=cut

sub init {
    my $self = shift;
    my %opt = @_;

    if ( defined $opt{clear_screen} ) {
        $self->clear_screen( $opt{clear_screen} );
    }
    elsif ( ! $ENV{TEST_VERBOSE} ) {
        $self->clear_screen( 1 );
    }
}

=head2 new_request

On the first call to new_request, the plugin adjusts the appenders.
This causes it to only have effect if it is run in a forked server
process, not in a test process.  If C<TEST_VERBOSE> is set, it does
not remove the Screen appender.

=cut

sub new_request {
    my $self = shift;
    return if $self->{init}++;

    Log::Log4perl->eradicate_appender("Screen") if $self->clear_screen;

    my $a = Jifty::Plugin::TestServerWarnings::Appender->new(name => "TestServerAppender");
    Log::Log4perl->get_logger("")->add_appender($a);
    Log::Log4perl->get_logger("")->level($WARN);
}

=head2 add_warnings WARN, WARN, ..

Takes the given warnings, and stores them away for later reporting.

=cut

sub add_warnings {
    my $self = shift;
    push @{ $self->{'stashed_warnings'} }, @_;
}

=head2 stashed_warnings

Returns the stored warnings, as a list.  This does not clear the list,
unlike L</encoded_warnings> or L</decoded_warnings>.

=cut


sub stashed_warnings {
    my $self = shift;
    return @{ $self->{'stashed_warnings'} || [] };
}

=head2 encoded_warnings

Returns the stored warnings, encoded using L<Storable>.  This also
clears the list of stashed warnings.

=cut

sub encoded_warnings {
    my $self = shift;
    my @warnings = splice @{ $self->{'stashed_warnings'} };

    return Storable::nfreeze(\@warnings);
}

=head2 decoded_warnings URI

Given the URI to a jifty server with this plugin enabled, retrieves
and decodes the stored warnings, returning them.  This will also clear
the server's stored list of warnings.

=cut

sub decoded_warnings {
    my $self = shift;
    my $base = shift;

    my $Test = Jifty::Test->builder;

    if ($Jifty::SERVER && $Jifty::SERVER->isa('Jifty::TestServer::Inline')) {
        return splice @{ $self->{'stashed_warnings'} };
    }

    my $uri = URI->new_abs( "/__jifty/test_warnings", $base );
    my $text = LWP::Simple::get($uri);

    return @{ Storable::thaw($text) || [] };
}

1;
