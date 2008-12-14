use strict;
use warnings;

package TestApp::Dispatcher::Dispatcher;
use Jifty::Dispatcher -base;

on '/redirect' => run { redirect('/woot') };

on 'on_not_exist_show' => run { show('/woot') };

on ['on_array1', 'on_array2'] => run { show('/woot') };

on ['on_array/1', 'on_array/2'] => run { show('/woot') };

on qr{^/on_re$} => run { show('/woot') };

on [ qr{^/on/array/re1$}, qr{^/on/array/re2$} ] => run { show('/woot') };

on 'on_arg' => run { set woot => 'x'; show('/woot') };

on 'on_run_run' => run { run { show('/woot') } };
on 'on_run_array' => [ show('/woot') ];
on 'on_run_array_run' => [ run { show('/woot') } ];


under 'under_any' => run { show('/woot') };
under 'under/some_any' => run {show('/woot') };

under qr{^/under_re/(.*)} => run { set woot => $1; show('/woot') };

under 'under_run_array_on' => [ on woot => run { show('/woot') } ];
under 'under_run_on_re' => run { on qr{^/woot$} => run { show('/woot') } };

under 'under/some' => run { on qr{^/woot$} => run { show('/woot') } };

# regression: check that /under_run_on_exist_run/not_exist doesn't match
under 'under_run_on_exist_run' => run { on exist => run { set woot => 'exist'; show('/woot') } };

{ # test caching
    under 'under_run_on_special' => run { on some_special => run { set woot => 'under'; show('/woot') } };
    on 'some_special' => run { set woot => 'top'; show('/woot') };
}

1;
