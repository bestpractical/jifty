use warnings;
use strict;

package Jifty::Plugin::SiteNews::View::News;
use Jifty::View::Declare -base;
use Jifty::View::Declare::CRUD;

template 'index.html' => page {


    h1 { 'This is your site news'};
    form {
        show('/news/list');
    }

};


template 'view' => sub {
    my $self = 'Jifty::View::Declare::CRUD';
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $update = new_action(
        class => 'Update' . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $self->get_record( $id )
    );

    my $record = $self->get_record($id);

    h1 { $record->title };
    blockquote {$record->content};
        hyperlink(
                label   => "Edit",
                class   => "editlink",
                onclick => {
                    replace_with => $self->fragment_for('update'),
                    args         => { object_type => $object_type, id => $id }
                },
        );


};





alias Jifty::View::Declare::CRUD under '/', { object_type => 'News', base_path => '/news', 
    fragment_for_view => '/news/view',
    fragment_for_new_item => '/news/new_item'

};

1;
