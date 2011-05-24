use strict;
use warnings;

package Jifty::Script::WriteCCJS;

use base qw/Jifty::Script/;

=head1 NAME

Jifty::Script::WriteCCJS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 options

Takes no options.

=head2 run

=cut

sub run {
    my $self = shift;
    Jifty->new;

    my ($ccjs) = Jifty->find_plugin('Jifty::Plugin::CompressedCSSandJS');

    die "CompressedCSSandJS is not enabled for @{[Jifty->app_class]}\n"
        unless $ccjs;

    die "External generation is not enabled\n"
        unless $ccjs->external_publish;

    $ccjs->generate_css;
    print "Wrote CSS to ".Jifty::CAS->key("ccjs","css-all").".css\n";
    $ccjs->generate_javascript;
    print "Wrote JS  to ".Jifty::CAS->key("ccjs","js-all").".js\n";
}

=head1 SEE ALSO

L<Jifty::Plugin::CompressedCSSandJS>

=head1 COPYRIGHT AND LICENSE

Copyright 2010, Best Practical Solutions.

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
