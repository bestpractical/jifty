package Jifty::Plugin::LeakDetector::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/leaks -- display full leak report
on 'leaks' => run {
    set 'skip_zero' => 1;
    show "leaks/all";
};

# http://your.app/leaks/all -- full leak report with non-leaked requests
on 'leaks/all' => run {
    set 'skip_zero' => 0;
    show "leaks/all";
};

# http://your.app/leaks/xxx -- display leak report for request ID xxx
on 'leaks/#' => run {
    abort(404) if $1 < 1;
    my $leak = $Jifty::Plugin::LeakDetector::requests[$1 - 1]
        or abort(404);
    set leak => $leak;
    show "leaks/one";
};

1;

