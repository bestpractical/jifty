use strict;
use warnings;

package Doxory::Model::Choice;
use Jifty::DBI::Schema;

use Doxory::Record schema {
    column name =>
        label is _('I need help deciding...'),
        render as 'textarea';

    column a =>
        label is _('On the one hand'),
        render as 'textarea',
        is mandatory;

    column b =>
        label is _('On the other hand'),
        render as 'textarea',
        is mandatory;

    column asked_by =>
        label is _('Asked by'),
        default is defer { Jifty->web->current_user->id },
        references Doxory::Model::User;
};
use Regexp::Common 'profanity_us';

sub validate_name {
    my ($self, $name) = @_;
    if ($name =~ /$RE{profanity}/i) {
        return (0, 'Would you speak like that in front of your mother? *cough*');
    }
    return 1;
}

sub canonicalize_name {
    my ($self, $name) = @_;

    $name =~ s/$RE{profanity}/**expletives**/gi;
    return $name;
}

sub in_favor_of_a {
    my $self = shift;
    $self->in_favor_of('a');
}

sub in_favor_of_b {
    my $self = shift;
    $self->in_favor_of('b');
}

sub in_favor_of {
    my $self = shift;
    my $suggestion = shift;
    my $votes = Doxory::Model::VoteCollection->new();
    Carp::cluck unless ($self->id);
    $votes->limit(column => 'choice', value => $self->id);
    $votes->limit(column => 'suggestion' => value => $suggestion);
    return $votes;
}

1;
