package Jifty::Plugin::AdminUI::View;
use strict;
use warnings;
use Jifty::View::Declare -base;
require Jifty::View::Declare::CRUD;

for my $class (Jifty->class_loader->models) {
    (my $alias = $class) =~ s/.*:://;
    alias Jifty::View::Declare::CRUD under "/__jifty/admin/model/$alias", {
        object_type => $alias,
    };
}

1;

=head1 NAME

Jifty::Plugin::AdminUI::View

=head1 DESCRIPTION

Mount a crud view for each class.

=cut

