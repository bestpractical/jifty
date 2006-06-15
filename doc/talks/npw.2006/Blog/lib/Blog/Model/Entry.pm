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

 use Regexp::Common 'profanity_us';
 sub canonicalize_body {
    my $self = shift;
    my $body = shift;
    $body =~ s/$RE{profanity}/**expletives**/gi;
    return $body;
 }

 sub validate_body {
    my $self = shift;
    my $body = shift;
    if ( $body =~ /$RE{profanity}/i) {
        return (0, 'Would you speak like that in front of your mother? *cough*'
        )
    }
    return (1, "OK");
 }


1;

