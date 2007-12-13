use strict;
use warnings;

package Jifty::Plugin::LeakTracker::View;
use Jifty::View::Declare -base;
use Scalar::Util 'blessed';

=head1 NAME

Jifty::Plugin::LeakTracker::View - Views for memory leak detection

=head1 TEMPLATES

=cut

template '/__jifty/admin/leaks/all' => page {
    my $skip_zero = get 'skip_zero';

    h1 { "Leaked Objects" }
    p {
        if ($skip_zero) {
            a { attr { href => "/__jifty/admin/leaks/all" }
                "Show zero-leak requests" }
        }
        else {
            a { attr { href => "/__jifty/admin/leaks" }
                "Hide zero-leak requests" }
        }
    }
    hr {}

    table {
        row {
            th { "ID" }
            th { "Leaks" }
            th { "Bytes leaked" }
            th { "Total size" }
            th { "Time" }
            th { "URL" }
        };

        for (@Jifty::Plugin::LeakTracker::requests)
        {
            next if $skip_zero && @{$_->{leaks}} == 0;

            row {
                cell { a {
                    attr { href => "/__jifty/admin/leaks/$_->{id}" }
                    $_->{id} } }

                cell { scalar @{$_->{leaks}} }
                cell { $_->{size} }
                cell { $_->{total} }
                cell { $_->{time} }
                cell { $_->{url} }
            };
        }
    }
};

template '/__jifty/admin/leaks/one' => page {
    my $leak = get 'leak';

    h1 { "Leaks from Request $leak->{id}" }
    ul {
        li { "URL: $leak->{url}" }
        li { "Time: $leak->{time}" }
        li { "Total memory used: $leak->{total} bytes" }
        li { "Objects leaked: " . scalar(@{$leak->{leaks}}) }
        li { "Memory leaked: $leak->{size} bytes" }
    }
    p { a { attr { href => "/__jifty/admin/leaks" } "Table of Contents" } }
    hr {}
    h2 { "Object types leaked:" }
    ul {
        my %seen;
        for (map { blessed $_ } @{ $leak->{leaks} }) {
            next if $seen{$_}++;
            li { $_ }
        }
    }
    hr {}
    pre { $leak->{objects} }
};

=head1 SEE ALSO

L<Jifty::Plugin::LeakTracker>, L<Jifty::Plugin::LeakTracker::Dispatcher>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
