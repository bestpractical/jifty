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
     'load'       => 'load',
     'replace'  => 'replace',
    )
}

=head2 run


=cut

sub run {
    my $self = shift;
    Jifty->new();

    if ($self->{dump}) { $self->dump(); }
    elsif ($self->{load}) { $self->load(); }
}

sub load {
    my $self = shift;
    my @content = <STDIN>;
    my $content = Jifty::YAML::Load(join('',@content));
    print Jifty::YAML::Dump($content)."\n";
    Jifty->handle->begin_transaction();
    # First the core stuff
    foreach my $class (grep { /^Jifty::Model/ } keys %$content) { 
        next if ($class =~ /^Jifty::Model::ModelClass(?:Column)?/); 
        $self->load_content($class => $content->{$class});
    }
    # Then the user stuff
    foreach my $class (grep {! /^Jifty::Model/ } keys %$content) { 
        $self->load_content($class => $content->{$class});
    }
}

sub load_content {
    my $self    = shift;
    my $class   = shift;
    my $content = shift;
    Jifty::Util->require($class)
        || Jifty->logger->log->fatal(
        "There's no locally defined class called $class. Without that, we can't insert records into it"
        );

    my $current_user = Jifty::CurrentUser->new( _bootstrap => 1 );
    foreach my $id ( sort keys %$content ) {
        my $obj = $class->new( current_user => $current_user );
        if ( $self->{'replace'} ) {
            $obj->load_by_cols( id => $content->{$id}->{id} );
            if ( $obj->id ) {
                $obj->delete();
            }
        }

        my ( $val, $msg ) = $class->create( %{ $content->{$id} } );
        if ($val) {
            Jifty->logger->log->info("Inserting $id into $class: $val");
        } else {
            Jifty->logger->log->fatal(
                "Failed to insert $id into $class: $val");

        }

    }

}


sub dump {
    my $self = shift;
    my $content = {};
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
                my $value = $item->__value($_->name);
                next unless defined $value;
                $ds->{$_->name} = $value;
             }
            $content->{$model}->{$item->id} = $ds;
        }
        

    }
    print Jifty::YAML::Dump($content)."\n";
    
}

1;
