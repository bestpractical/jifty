#!/usr/bin/env perl
package Jifty::Plugin::SQLQueries;
use base qw/Jifty::Plugin/;
use strict;
use warnings;

our @requests;
our @slow_queries;

=head1 NAME

Jifty::Plugin::SQLQueries

=head1 DESCRIPTION

SQL query logging and reporting for your Jifty app

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - SQLQueries: {}

This makes the following URLs available:

View the top-level query report (how many queries each request had)

    http://your.app/__jifty/admin/queries

View the top-level query report, including zero-query requests

    http://your.app/__jifty/admin/queries/all

View an individual request's detailed query report (which queries were made,
where, how long they took, etc)

    http://your.app/__jifty/admin/queries/3

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
    Jifty->handle->log_sql_hook(SQLQueryPlugin => sub { Carp::longmess });
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

        # keep track of the ten slowest queries so far
        if ($duration > $slow_queries[0][3]) {
            push @slow_queries, $_;
            @slow_queries = sort { $a->[3] <=> $b->[3] } @slow_queries;
            shift @slow_queries if @slow_queries > 9;
        }
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

