package Jifty::Plugin::AdminUI::View;
use strict;
use warnings;
use Jifty::View::Declare -base;
require Jifty::View::Declare::CRUD;

# Mount a crud view for each class
for my $class (Jifty->class_loader->models) {
    (my $alias = $class) =~ s/.*:://;
    alias Jifty::View::Declare::CRUD under "/__jifty/admin/model/$alias", {
        object_type => $alias,
    };
}

1;

