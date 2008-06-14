use strict;
use warnings;

package Jifty::Plugin::SiteNews::Mixin::Model::News;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

our @EXPORT = qw(current_user_can);

=head1 NAME

Jifty::Plugin::SiteNews::Mixin::Model::News - News model

=cut

use Jifty::Record schema {

    my $user_class = Jifty->app_class('Model', 'User');

#column author_id => refers_to $user_class; label is 'Author';
column created   =>
  type is 'timestamp',
  filters are qw( Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
  label is 'Created on';
column title     =>
  type is 'text',
  label is 'Title';
column content   =>
  type is 'text',
  label is 'Article',
  render_as is 'Textarea';
};

=head2 create

Create the News model. Takes a paramhash with keys author_id, created, title, and content.

=cut

sub create {
    my $self = shift;
    my %args = (
        author_id => $self->current_user->id,
        created   => DateTime->now->iso8601,
        title     => undef,
        content   => undef,
        @_
    );

    $self->SUPER::create(%args);
}

=head2 current_user_can

Anyone can read news articles, only administrators can create, update,
or delete them.

=cut

sub current_user_can {
    my $self = shift;
    my $right = shift;

    return 1;
    # Anyone can read
    return 1 if ($right eq "read");
    
    # Only admins can do other things
    return $self->current_user->user_object->access_level eq "staff";
}

=head2 as_atom_entry

Returns the task as an L<XML::Atom::Entry> object.

=cut

sub as_atom_entry {
    my $self = shift;

    my $author = XML::Atom::Person->new;
    $author->name($self->author->name);

    my $entry = XML::Atom::Entry->new;
    $entry->author( $author );
    $entry->title( $self->title );
    $entry->content( $self->content);
    return $entry;
}

1;
