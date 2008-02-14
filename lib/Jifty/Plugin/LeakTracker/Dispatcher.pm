package Jifty::Plugin::LeakTracker::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/__jifty/admin/leaks -- display full leak report
on '/__jifty/admin/leaks' => run {
    set 'skip_zero' => 1;
    show "/__jifty/admin/leaks/all";
};

# http://your.app/__jifty/admin/leaks/all -- leak report with 0-leak requests
on '/__jifty/admin/leaks/all' => run {
    set 'skip_zero' => 0;
    show "/__jifty/admin/leaks/all";
};

# http://your.app/__jifty/admin/leaks/xxx -- display leak report for request ID
on '/__jifty/admin/leaks/#' => run {
    abort(404) if $1 < 1;
    my $leak = $Jifty::Plugin::LeakTracker::requests[$1 - 1]
        or abort(404);
    set leak => $leak;
    show "/__jifty/admin/leaks/one";
};

=head1 SEE ALSO

L<Jifty::Plugin::LeakTracker>, L<Jifty::Plugin::LeakTracker::View>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

