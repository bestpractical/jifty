use 5.008;
use utf8;
use strict;
use warnings;

package Jifty::Plugin::Tag::Mixin::Model;
use base 'Jifty::DBI::Record::Plugin';

use Jifty::DBI::Schema;
use Jifty::Plugin::Tag::Record schema {};

our @EXPORT = qw(tags has_tag add_tag delete_tag delete_all_tags);

sub tags {
    my $self = shift;

    my $res = Jifty->app_class('Model', 'TagCollection')->new;
    my ($model) = (ref($self) =~ /([^:]+)$/);
    $res->limit( column => 'model', value => $model, case_sensetive => 0 );
    $res->limit( column => 'record', value => $self->id );
    return $res;
}

sub add_tag {
    my $self = shift;
    my $value = shift;
    my %opt = @_;

    if ( !$opt{'no_check'} && $self->has_tag($value) ) {
        return (0, _("Record already tagged with '%1'", $value))
            unless $opt{'exist_ok'};
        return (1, _('Added a tag'));
    }
    my $tag = Jifty->app_class('Model', 'Tag')->new;
    return $tag->create( record => $self, value => $value );
}

sub delete_tag {
    my $self = shift;
    my $value = shift;
    my %opt = @_;

    my $tag = $self->has_tag( $value );
    unless ( $tag ) {
        return (0, _("Record has no tag '%1'", $value))
            unless $opt{'not_exist_ok'};
        return (1, _("Deleted a tag"));
    }
    return $tag->delete;
}

sub delete_all_tags {
    my $self = shift;

    my $tags = $self->tags;
    while ( my $t = $tags->next ) {
        my ($s, $msg) = $t->delete;
        return ($s, $msg) unless $s;
    }
    return (1, _('Deleted all tags of the record'));
}

sub has_tag {
    my $self = shift;
    my $value = shift;

    my $res = Jifty->app_class('Model', 'Tag')->new;
    $res->load_by_cols(
        model  => (ref($self) =~ /([^:]+)$/)[0],
        record => $self->id,
        value  => $value,
    );
    return undef unless $res->id;
    return $res;
}

1;
