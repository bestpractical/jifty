package Jifty::Plugin::SQLQueries;
use strict;
use warnings;
use base 'Jifty::Plugin';

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

    return scalar @$log . ' queries';
}

1;

