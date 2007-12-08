use strict;
use warnings;

package Jifty::Plugin::SQLQueries::View;
use Jifty::View::Declare -base;
use Scalar::Util 'blessed';

=head1 NAME

Jifty::Plugin::SQLQueries::View - Views for database queries

=head1 TEMPLATES

=cut

template '/__jifty/admin/queries/all' => page {
    my $skip_zero = get 'skip_zero';

    h1 { "Queries" }
    p {
        if ($skip_zero) {
            a { attr { href => "/__jifty/admin/queries/all" }
                "Show zero-query requests" }
        }
        else {
            a { attr { href => "/__jifty/admin/queries" }
                "Hide zero-query requests" }
        }
        a { attr { href => "/__jifty/admin/queries/clear" }
            "Clear query log" }
    }
    hr {}

    h3 { "Slowest queries" };
    table {
        row {
            th { "Time taken" };
            th { "Query" };
        };

        for (reverse @Jifty::Plugin::SQLQueries::slow_queries)
        {
            my ($time, $statement, $bindings, $duration, $misc) = @$_;
            row {
                cell { $duration };
                cell { $statement };
            };
        }
    };

    hr {};

    h3 { "All queries" };
    table {
        row {
            th { "ID" }
            th { "Queries" }
            th { "Time taken" }
            th { "URL" }
        };

        for (@Jifty::Plugin::SQLQueries::requests)
        {
            next if $skip_zero && @{ $_->{queries} } == 0;

            row {
                cell { a {
                    attr { href => "/__jifty/admin/queries/$_->{id}" }
                    $_->{id} } }

                cell { scalar @{ $_->{queries} } }
                cell { $_->{duration} }
                cell { $_->{url} }
            };
        }
    }
};

template '/__jifty/admin/queries/one' => page {
    my $query = get 'query';

    h1 { "Queries from Request $query->{id}" }
    ul {
        li { "URL: $query->{url}" }
        li { "At: " . $query->{time} }
        li { "Time taken: $query->{duration}" }
        li { "Queries made: " . @{ $query->{queries} } }
    }
    p { a { attr { href => "/__jifty/admin/queries" }
            "Table of Contents" } };

    for ( @{ $query->{queries} } ) {
        hr {};
        set query => $_;
        show '/__jifty/admin/queries/query';
    }
};

template '/__jifty/admin/queries/query' => sub {
    my ($time, $statement, $bindings, $duration, $misc) = @{ get 'query' };

    h4 { pre { $statement } };
    ul {
        li { "At: " . gmtime($time) };
        li { "Time taken: $duration" };
    }
    h5 { "Bindings:" }
    ol {
        li { $_ } for @$bindings;
    }
    h5 { "Stack trace:" }
    pre {
        $misc->{SQLQueryPlugin};
    }
};

=head1 SEE ALSO

L<Jifty::Plugin::SQLQueries>, L<Jifty::Plugin::SQLQueries::Dispatcher>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

