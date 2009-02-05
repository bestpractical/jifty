use strict;
use warnings;

package Jifty::Plugin::TestServerWarnings;
use base qw/Jifty::Plugin/;

use LWP::Simple qw//;
use Jifty::Plugin::TestServerWarnings::Appender;

__PACKAGE__->mk_accessors(qw(clear_screen));

=head2 NAME

Jifty::Plugin::TestServerWarnings - Stores server warnings away for later fetching

=head2 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - TestServerWarnings:
        clear_screen: 1

=head2 DESCRIPTION

This plugin add a new appender L<Jifty::Plugin::TestServerWarnings::Appender>
on the first request it sees, which stores away all messages it receives. 
It also removes the default "Screen" appender unless clear_screen in
config.yml is set to be false or env TEST_VERBOSE is true.

The warnings can be retrieved by a client-side process by calling 
L</decoded_warnings> with a base URI to the server.

This plugin is automatically added for all jifty tests.

=head2 METHODS

=head3 init

set clear_screen to 1 if the clear_screen in config.yml is set to be true,
if it's not set at all, set it to 1 if TEST_VERBOSE is set to be true.

=cut

sub init {
    my $self = shift;
    my %opt = @_;
    if ( defined $opt{clear_screen} ) {
        $self->clear_screen( 1 ) if $opt{clear_screen};
    }
    elsif ( ! $ENV{TEST_VERBOSE} ) {
        $self->clear_screen( 1 );
    }
}

=head3 new_request

On the first call to new_request, the plugin adjusts the appenders.
This causes it to only have effect if it is run in a forked server
process, not in a test process.  If C<TEST_VERBOSE> is set, it does
not remove the Screen appender.

=cut

sub new_request {
    my $self = shift;
    return if $self->{init}++;

    my $root = Log::Log4perl->get_logger("");
    $root->remove_appender("Screen") if $self->clear_screen;

    my $a = Jifty::Plugin::TestServerWarnings::Appender->new(name => "TestServerAppender");
    $root->add_appender($a);
}

=head3 add_warnings WARN, WARN, ..

Takes the given warnings, and stores them away for later reporting.

=cut

sub add_warnings {
    my $self = shift;
    push @{ $self->{'stashed_warnings'} }, @_;
}

=head3 stashed_warnings

Returns the stored warnings, as a list.  This does not clear the list,
unlike L</encoded_warnings> or L</decoded_warnings>.

=cut


sub stashed_warnings {
    my $self = shift;
    return @{ $self->{'stashed_warnings'} || [] };
}

=head3 encoded_warnings

Returns the stored warnings, encoded using L<Storable>.  This also
clears the list of stashed warnings.

=cut

sub encoded_warnings {
    my $self = shift;
    my @warnings = splice @{ $self->{'stashed_warnings'} };

    return Storable::nfreeze(\@warnings);
}

=head3 decoded_warnings URI

Given the URI to a jifty server with this plugin enabled, retrieves
and decodes the stored warnings, returning them.  This will also clear
the server's stored list of warnings.

=cut

sub decoded_warnings {
    my $self = shift;
    my $base = shift;

    my $uri = URI->new_abs( "/__jifty/test_warnings", $base );
    my $text = LWP::Simple::get($uri);

    return @{ Storable::thaw($text) };
}

1;
