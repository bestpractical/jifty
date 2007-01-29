use warnings;
use strict;

package Jifty::Script::Database;
use base qw/App::CLI::Command/;


use File::Path ();


=head1 NAME

Jifty::Script::Database 

=head1 DESCRIPTION

When you're getting started with Jifty, this is the server you
want. It's lightweight and easy to work with.

=head1 API

=head2 options


=cut

sub options {
    (
     'dump'       => 'dump',
    )
}

=head2 run


=cut

sub run {
    my $self = shift;
    Jifty->new();
    my %content = {};
 foreach my $model (Jifty->class_loader->models, qw(Jifty::Model::Metadata Jifty::Model::ModelClass Jifty::Model::ModelClassColumn)) {
        next unless $model->isa('Jifty::Record');
        my $collection = $model."Collection";
        Jifty::Util->require($collection);
        my $records = $collection->new;
        $records->unlimit();

        foreach my $item(@{$records->items_array_ref}) {
            my $ds = {};
             for ($item->columns) {
                 next if $_->virtual;
                $ds->{$_->name} = $item->__value($_->name);
             }
            $content{$model}->{$item->id} = $ds;
        }
        

    }
    print Jifty::YAML::Dump(\%content)."\n";
    
}

1;
