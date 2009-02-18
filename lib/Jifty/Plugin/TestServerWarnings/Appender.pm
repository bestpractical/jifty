package Jifty::Plugin::TestServerWarnings::Appender;
use strict;
use warnings;
use base qw/Log::Log4perl::Appender/;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub log {
    my $self = shift;
    my $plugin = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");
    my $message = $_[0]{message};
    $message = join('',@{$message}) if ref $message eq "ARRAY";
    $plugin->add_warnings($message);
}

1;
