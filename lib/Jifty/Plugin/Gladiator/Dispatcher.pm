package Jifty::Plugin::Gladiator::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/arena
on '/__jifty/admin/arena' => run {
    set 'skip_zero' => 1;
    show "/__jifty/admin/arena/all";
};

# http://your.app/arena/all
on '/__jifty/admin/arena/all' => run {
    set 'skip_zero' => 0;
    show "/__jifty/admin/arena/all";
};

# http://your.app/arena/clear
on '/__jifty/admin/arena/clear' => run {
    @Jifty::Plugin::Gladiator::requests = ();
    set 'skip_zero' => 1;
    redirect "/__jifty/admin/arena";
};

# http://your.app/arena/xxx
on '/__jifty/admin/arena/#' => run {
    abort(404) if $1 < 1;
    my $arena = $Jifty::Plugin::Gladiator::requests[$1 - 1]
        or abort(404);
    set arena => $arena;
    show "/__jifty/admin/arena/one";
};

=head1 SEE ALSO

L<Jifty::Plugin::Gladiator>, L<Jifty::Plugin::Gladiator::View>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


