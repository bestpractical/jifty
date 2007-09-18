use strict;
use warnings;

package Jifty::Plugin::LeakDetector::View;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::LeakDetector::View - Views for memory leak detection

=head1 TEMPLATES

=head2 leaks/chart

This shows a chart using L<Chart>. It expects to find the arguments in the C<args> parameter, which is setup for it in L<Jifty::Plugin::Chart::Dispatcher>.

This will output a PNG file unless there is an error building the chart.

=cut

template 'leaks/all' => sub {
    html {
        body {
            table {
                row {
                    th { "ID" }
                    th { "Leaks" }
                    th { "Bytes leaked" }
                    th { "Time" }
                    th { "URL" }
                };

                for (@Jifty::Plugin::LeakDetector::requests)
                {
                    row {
                        cell { a { attr { href => "leaks/$_->{id}" }
                                   $_->{id} } }

                        cell { $_->{leaks} }
                        cell { $_->{size} }
                        cell { $_->{time} }
                        cell { $_->{url} }
                    };
                }
            }
        }
    }
};

template 'leaks/one' => sub {
    my $leak = get 'leak';

    html {
        body {
            h1 { "Leaks from Request $leak->{id}" }
            ul {
                li { "URL: $leak->{url}" }
                li { "Time: $leak->{time}" }
                li { "Objects leaked: $leak->{leaks}" }
                li { "Total memory leaked: $leak->{size} bytes" }
            }
            p { a { attr { href => "/leaks" } "Table of Contents" } }
            hr {}
            pre { $leak->{objects} }
        }
    }
};

=head1 SEE ALSO

L<Jifty::Plugin::LeakDetector::Dispatcher>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
