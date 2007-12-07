#!/usr/bin/env perl
package Jifty::Plugin::Queries;
use base qw/Jifty::Plugin/;
use strict;
use warnings;

our @requests;

=head1 NAME

Jifty::Plugin::Queries

=head1 DESCRIPTION

Query logging and reporting for your Jifty app

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Queries: {}

This makes the following URLs available:

View the top-level query report (how many queries each request had)

    http://your.app/queries

View the top-level query report, including zero-query requests

    http://your.app/queries/all

View an individual request's detailed query report (which queries were made,
where, how long they took, etc)

    http://your.app/queries/3

=head2 init

This makes sure that each request is wrapped with query logging.

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;

    Jifty->add_trigger(
        post_init => \&post_init
    );

    Jifty::Handler->add_trigger(
        before_request => \&before_request
    );

    Jifty::Handler->add_trigger(
        after_request  => \&after_request
    );
}

=head2 post_init

This sets up L<Jifty::DBI>'s query logging, and is called at the end of
C<< Jifty->new >>

=cut

sub post_init {
    Jifty->handle or return;

    require Carp;

    Jifty->handle->log_sql_statements(1);
    Jifty->handle->log_sql_hook(QueryPlugin => sub { Carp::longmess });
}

=head2 before_request

Clears the SQL log so you only get the request's queries

=cut

sub before_request {
    Jifty->handle or return;

    Jifty->handle->clear_sql_statement_log();
}

=head2 after_request

Logs the queries made (at level DEBUG)

=cut

sub after_request {
    Jifty->handle or return;

    my $handler = shift;
    my $cgi = shift;

    my $total_time = 0;
    my @log = Jifty->handle->sql_statement_log();
    for (@log) {
        my ($time, $statement, $bindings, $duration, $results) = @$_;

        Jifty->log->debug(sprintf 'Query (%.3fs): "%s", with bindings: %s',
                            $duration,
                            $statement,
                            join ', ', @$bindings);
        $total_time += $duration;
    }

    push @requests, {
        id => 1 + @requests,
        duration => $total_time,
        url => $cgi->url(-absolute=>1,-path_info=>1),
        time => scalar gmtime,
        queries => \@log,
    };
}

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

