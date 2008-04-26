package Jifty::Plugin::SQLQueries::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/queries -- display full query report
on '/__jifty/admin/queries' => run {
    set 'skip_zero' => 1;
    show "/__jifty/admin/queries/all";
};

# http://your.app/queries/all -- full query report with non-query requests
on '/__jifty/admin/queries/all' => run {
    set 'skip_zero' => 0;
    show "/__jifty/admin/queries/all";
};

# http://your.app/queries/clear -- clear query log
on '/__jifty/admin/queries/clear' => run {
    @Jifty::Plugin::SQLQueries::requests = ();
    @Jifty::Plugin::SQLQueries::slow_queries = ();
    @Jifty::Plugin::SQLQueries::halo_queries = ();
    set 'skip_zero' => 1;
    redirect "/__jifty/admin/queries";
};

# http://your.app/queries/xxx -- display query report for request ID xxx
on '/__jifty/admin/queries/#' => run {
    abort(404) if $1 < 1;
    my $query = $Jifty::Plugin::SQLQueries::requests[$1 - 1]
        or abort(404);
    set query => $query;
    show "/__jifty/admin/queries/one";
};

=head1 SEE ALSO

L<Jifty::Plugin::SQLQueries>, L<Jifty::Plugin::SQLQueries::View>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

