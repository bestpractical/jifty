#!/usr/bin/env perl
package ShrinkURL::Action::CreateShrunkenURL;
use strict;
use warnings;

use base qw/Jifty::Action::Record::Create/;
sub record_class { 'ShrinkURL::Model::ShrunkenURL' }

# have we already shrunk this URL? if so, no need to do it again!
sub take_action {
    my $self = shift;
    my $url = $self->argument_value('url');

    my $shrunkenurl = ShrinkURL::Model::ShrunkenURL->new;
    $shrunkenurl->load_by_cols(url => $url);

    if ($shrunkenurl->id) {
        $self->record($shrunkenurl);
        $self->result->content(id => $shrunkenurl->id);
        $self->report_success;
        return $shrunkenurl->id;
    }

    return $self->SUPER::take_action(@_);
}

sub report_success {
    my $self = shift;
    $self->result->message(_("URL shrunked to %1", $self->record->shrunken));
}

1;

