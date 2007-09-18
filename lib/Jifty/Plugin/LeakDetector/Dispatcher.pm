package Jifty::Plugin::LeakDetector::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/leaks -- display full leak report
on 'leaks' => run {
        show "leaks/all";
};

# http://your.app/leaks/xxx -- display leak report for request ID xxx
on 'leaks/#' => run {
    my $leak = $Jifty::Plugin::LeakDetector::requests[$1]
        or abort(404);
    set leak => $leak;
    set leakid => $1;
    show "leaks/one";
};

1;

