package Jifty::Plugin::SQLQueries;
use strict;
use warnings;
use base 'Jifty::Plugin';
use List::Util 'sum';
use Carp;
use Scalar::Util;

__PACKAGE__->mk_accessors(qw(stacktrace explain));

sub prereq_plugins { 'RequestInspector' }

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opts = (
        stacktrace => 1,
        explain    => 0,
        @_,
    );
    $self->explain($opts{explain});
    $self->stacktrace($opts{stacktrace});

    Jifty->add_trigger(
        post_init => sub { $self->post_init(@_) }
    );
}

sub post_init {
    my $self = shift;
    Jifty->handle or return;

    if ($self->stacktrace) {
        Jifty->handle->log_sql_hook(SQLQueryPlugin_Stacktrace => sub {
            my ($time, $statement, $bindings, $duration) = @_;
            __PACKAGE__->log->debug(sprintf 'Query (%.3fs): "%s", with bindings: %s',
                                $duration,
                                $statement,
                                join ', ',
                                    map { defined $_ ? $_ : 'undef' } @$bindings,
            );
            return Carp::longmess("Query");
        });
    }

    if ($self->explain) {
        Jifty->handle->log_sql_hook(SQLQueryPlugin_Explain => sub {
            my ($time, $statement, $bindings, $duration) = @_;
            my $ret = Jifty->handle->dbh->selectcol_arrayref( "EXPLAIN $statement", {}, @{$bindings});
            return $ret;
        });
    }
}

sub inspect_before_request {
    my $self = shift;
    Jifty->handle->log_sql_statements(1);
    Jifty->handle->clear_sql_statement_log;
}

sub inspect_after_request {
    Jifty->handle->log_sql_statements(0);
    my $ret = [ Jifty->handle->sql_statement_log ];
    Jifty->handle->clear_sql_statement_log;
    return $ret;
}

sub inspect_render_summary {
    my $self = shift;
    my $log = shift;

    my $count = @$log;
    my $seconds = sprintf '%.2g', sum map { $_->[3] } @$log;

    return _("%quant(%1,query,queries) taking %2s", $count, $seconds);
}

sub inspect_render_analysis {
    my $self = shift;
    my $log = shift;
    my $id = shift;

    Jifty::View::Declare::Helpers::render_region(
        name => 'sqlqueries',
        path => '/__jifty/admin/requests/queries',
        args => {
            id => $id,
        },
    );
}

1;

__END__

=head1 NAME

Jifty::Plugin::SQLQueries - Inspect your app's SQL queries

=head1 DESCRIPTION

This plugin will log each SQL query, its duration, its bind
parameters, and its stack trace. Such reports are available at:

    http://your.app/__jifty/admin/requests

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - SQLQueries: {}

You can turn on and off the stacktrace, as well as an "EXPLAIN" of
each query, using options to the plugin:

 framework:
   Plugins:
     - SQLQueries:
         stacktrace: 0
         explain: 1

The plugin defaults to logging the stack trace, but not the explain.

=head1 METHODS

=head2 init

Sets up a L</post_init> hook.

=head2 inspect_before_request

Clears the query log so we don't log any unrelated previous queries.

=head2 inspect_after_request

Stash the query log.

=head2 inspect_render_summary

Display how many queries and their total time.

=head2 inspect_render_analysis

Render a template with all the detailed information.

=head2 post_init

Tells L<Jifty::DBI> to log queries in a way that records stack traces.

=head2 prereq_plugins

This plugin depends on L<Jifty::Plugin::RequestInspector>.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

