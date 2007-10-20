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

        # for the benefit of report_success
        $self->record($shrunkenurl);

        # for the benefit of the template that displays new shrunken URLs
        # this is called in a superclass which we bypass
        $self->result->content(id => $shrunkenurl->id);

        # this too is called in a superclass
        $self->report_success;

        # Create actions return object's ID
        return $shrunkenurl->id;
    }

    return $self->SUPER::take_action(@_);
}

# display a nice little message for the user
sub report_success {
    my $self = shift;
    $self->result->message(_("URL shrunked to %1", $self->record->shrunken));
}

1;

