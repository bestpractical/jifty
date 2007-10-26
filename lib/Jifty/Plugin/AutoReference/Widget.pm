use strict;
use warnings;

package Jifty::Plugin::AutoReference::Widget;
use base qw/ Jifty::Web::Form::Field /;

=head1 NAME

Jifty::Plugin::AutoReference::Widget - an autocomplete widget for references

=head1 SYNOPSIS

  use MyApp::Record schema {
      column employer =>
          references MyApp::Model::Company,
          label is 'Employer',
          is AutoReference,
          ;
  };

=head1 DESCRIPTION

Provides a special autocomplete widget that can be useful when there are too many items for a Select box to be practical.

B<WARNING:> As of this writing, it should be noted that this widget does not degrade gracefully. If you need a widget that operates properly even when JavaScript is unavailable, this widget won't do that job at this time.

=cut

sub render {
    my $self = shift;

    $self->autocompleter(1);
    return $self->SUPER::render(@_);
}

sub _record_description {
    my $self = shift;

    my $value = $self->default_value;

    my $name      = $self->name;
    my $column    = $self->action->record->column($name);
    my $reference = $column->refers_to;
    my $brief     = $reference->can('_brief_description') ?
                        $reference->_brief_description : 'name';

    my $record = $self->action->record->$name;
    if ($record and $record->id) {
        return $record->$brief . ' [id:'. $record->id . ']';
    }
    else {
        return;
    }
}

sub _switch_current_value_temporarily(&$) {
    my $code = shift;
    my $self = shift;
    
    my $description = $self->_record_description;

    if ($self->sticky_value and $self->sticky) {
        my $old_value = $self->sticky_value;
        $self->sticky_value($description);
        $code->();
        $self->sticky_value($old_value);
    }

    else {
        my $old_value = $self->default_value;
        $self->default_value($description);
        $code->();
        $self->default_value($old_value);
    }
}

sub render_widget {
    my $self = shift;

    # Render the shown autocomplete field first
    my $input_name = $self->input_name;
    $self->input_name($input_name.'-display');
    my $element_id = $self->element_id;
    $self->_element_id($element_id.'-display');
    my $class = $self->class;
    $self->class(join ' ', ($class||''), 'text');
    _switch_current_value_temporarily {
        $self->SUPER::render_widget(@_);
    } $self;
    $self->input_name($input_name);
    $self->_element_id($element_id);
    $self->class($class);

    # Render the hidden value field second
    $self->type('hidden');
    $self->SUPER::render_widget(@_);
    $self->type('text');

    return '';
}

sub render_value {
    my $self = shift;

    _switch_current_value_temporarily {
        $self->SUPER::render_value(@_);
    } $self;

    return '';
}

sub autocomplete_javascript {
    my $self = shift;
    return qq{new Jifty.Plugin.AutoReference('@{[$self->element_id]}-display','@{[$self->element_id]}','@{[$self->element_id]}-autocomplete')};
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
