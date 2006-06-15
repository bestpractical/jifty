use strict;
use warnings;

package Blog::Model::Entry::Schema;
use Jifty::DBI::Schema;

# Your column definitions go here.  See L<Jifty::DBI::Schema> for
# documentation about how to write column definitions.

column title =>
      type is 'text',
      default is 'Untitled';
 
column body =>
      type is 'text',
      render_as 'Textarea';

package Blog::Model::Entry;
use base qw/Blog::Record/;

# Your model-specific methods go here.

1;

