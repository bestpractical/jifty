use warnings;
use strict;

package Jifty::Plugin::SiteNews::View::News;
use Jifty::View::Declare -base;
use base 'Jifty::View::Declare::CRUD';

=head1 NAME

Jifty::Plugin::SiteNews::View::News - /news pages for your app

=head1 DESCRIPTION

The /news pages for L<Jifty::Plugin::SiteNews>

=cut


=head2 object_type

News

=cut

sub object_type { 'News' }

template search_region => sub {''};

template 'index.html' => page {
    my $self = shift;
    title is  'Site news' ;
    form {
            render_region(
                name     => 'newslist',
                path     =>  $self->fragment_base_path.'/list');
    }

};


template 'view' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $update = new_action(
        class => 'Update' . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $self->_get_record( $id )
    );

    my $record = $self->_get_record($id);

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

1;
