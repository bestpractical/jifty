package Jifty::Plugin::SQLQueries;
use strict;
use warnings;
use base 'Jifty::Plugin';
use List::Util 'sum';

sub prereq_plugins { 'RequestInspector' }

sub init {
    my $self = shift;
    return if $self->_pre_init;

    Jifty->add_trigger(
        post_init => \&post_init
    );
}

sub post_init {
    Jifty->handle or return;

    require Carp;

    Jifty->handle->log_sql_statements(1);
    Jifty->handle->log_sql_hook(SQLQueryPlugin => sub {
        my ($time, $statement, $bindings, $duration) = @_;
        __PACKAGE__->log->debug(sprintf 'Query (%.3fs): "%s", with bindings: %s',
                            $duration,
                            $statement,
                            join ', ',
                                map { defined $_ ? $_ : 'undef' } @$bindings,
        );
        return Carp::longmess;
    });
}

sub inspect_before_request {
    Jifty->handle->clear_sql_statement_log;
}

sub inspect_after_request {
    return [ Jifty->handle->sql_statement_log ];
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

