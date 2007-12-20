use strict;
use warnings;

package Jifty::Plugin::Gladiator::View;
use Jifty::View::Declare -base;
use Scalar::Util 'blessed';

=head1 NAME

Jifty::Plugin::Gladiator::View - Views for database arena

=head1 TEMPLATES

=cut

template '/__jifty/admin/arena/all' => page {
    my $skip_zero = get 'skip_zero';

    h1 { "Queries" }
    p {
        if ($skip_zero) {
            a { attr { href => "/__jifty/admin/arena/all" }
                "Show zero-arena requests" }
        }
        else {
            a { attr { href => "/__jifty/admin/arena" }
                "Hide zero-arena requests" }
        }
        a { attr { href => "/__jifty/admin/arena/clear" }
            "Clear arena log" }
    }
    hr {}

    h3 { "All arena" };
    table {
        row {
            th { "ID"         }
            th { "New values" }
            th { "New types"  }
            th { "All values" }
            th { "All types"  }
            th { "URL"        }
        };

        for (@Jifty::Plugin::Gladiator::requests)
        {
            next if $skip_zero && $_->{new_values} == 0;

            row {
                cell { a {
                    attr { href => "/__jifty/admin/arena/$_->{id}" }
                    $_->{id} } }

                cell { $_->{new_values} }
                cell { $_->{new_types}  }
                cell { $_->{all_values} }
                cell { $_->{all_types}  }
                cell { $_->{url}        }
            };
        }
    }
};

template '/__jifty/admin/arena/one' => page {
    my $arena = get 'arena';

    h1 { "Queries from Request $arena->{id}" }
    ul {
        li { "URL: $arena->{url}" }
        li { "At: " . $arena->{time} }
        li { "New values: $arena->{new_values}" }
        li { "New types:  $arena->{new_types}"  }
        li { "All values: $arena->{all_values}" }
        li { "All types:  $arena->{all_types}"  }
    }

    table {
        row {
            th { "Type" }
            th { "New" }
            th { "All" }
        };

        my @sorted = sort {
            $arena->{diff}->{$b}->{new} <=> $arena->{diff}->{$a}->{new}
                                         ||
            $arena->{diff}->{$b}->{all} <=> $arena->{diff}->{$a}->{all}
        } keys %{ $arena->{diff} };

        for my $type (@sorted) {
            row {
                cell { $type }
                cell { $arena->{diff}->{$type}->{new} }
                cell { $arena->{diff}->{$type}->{all} }
            }
        }
    }
};

=head1 SEE ALSO

L<Jifty::Plugin::Gladiator>, L<Jifty::Plugin::Gladiator::Dispatcher>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


