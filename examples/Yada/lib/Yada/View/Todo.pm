package Yada::View::Todo;
use strict;
use base 'Jifty::View::Declare::CRUD';
use Jifty::View::Declare -base;

template 'view_brief' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $record = $self->_get_record($id);

    div { {class is "description" };
	  outs($record->description);
	  hyperlink(label => 'details',
		    onclick => [{region => 'test_region',
				 replace_with => $self->fragment_for('view'),
				 args         => { id => $id },
				}]);
      };
};

1;
