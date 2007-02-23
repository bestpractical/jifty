#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';

use Jifty::SubTest;
use Log::Log4perl;
use Jifty::Test tests => 1;

my $config = Jifty::YAML::LoadFile($ENV{JIFTY_TEST_CONFIG});
$config->{'framework'}->{'Database'}->{'Version'} = '0.0.2';
Jifty::YAML::DumpFile($ENV{JIFTY_TEST_CONFIG}, $config);

my $logger = Log::Log4perl->get_logger('SchemaTool');
$logger->add_appender(
    my $test_appender = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::String',
        name      => 'Test',
        min_level => 'WARN',
        layout    => 'Log::Log4perl::Layout::SimpleLayout',
    )
);

my $schema = Jifty::Script::Schema->new;
$schema->{setup_tables} = 1;
$schema->run;

my $failed_messages = $test_appender->string;
ok(!$failed_messages, 'no warnings or worse');
