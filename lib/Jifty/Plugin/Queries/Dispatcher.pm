package Jifty::Plugin::Queries::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/queries -- display full query report
on '/queries' => run {
    set 'skip_zero' => 1;
    show "/queries/all";
};

# http://your.app/queries/all -- full query report with non-query requests
on '/queries/all' => run {
    set 'skip_zero' => 0;
    show "/queries/all";
};

# http://your.app/queries/clear -- clear query log
on '/queries/clear' => run {
    @Jifty::Plugin::Queries::requests = ();
    set 'skip_zero' => 1;
    redirect "/queries";
};

# http://your.app/queries/xxx -- display query report for request ID xxx
on '/queries/#' => run {
    abort(404) if $1 < 1;
    my $query = $Jifty::Plugin::Queries::requests[$1 - 1]
        or abort(404);
    set query => $query;
    show "/queries/one";
};

=head1 SEE ALSO

L<Jifty::Plugin::Queries>, L<Jifty::Plugin::Queries::View>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

