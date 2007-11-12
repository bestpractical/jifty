use strict;
use warnings;

package Jifty::Plugin::AutoReference;
use base qw/ Jifty::Plugin /;

use Jifty::Plugin::AutoReference::Widget;

=head1 NAME

Jifty::Plugin::AutoReference - a plugin to provide a special reference completer

=head1 SYNOPSIS

Add this to your F<config.yml>:

  Plugins:
   - AutoReference: {}

and then this to your models:

  use MyApp::Record schema {
      column employer =>
          references MyApp::Model::Company,
          label is 'Employer',
          is AutoReference,
          ;
  };

=head1 DESCRIPTION

Provides a special autocompletion widget for reference columns. See L<Jifty::Plugin::AutoReference::Widget>.

=head1 METHODS

=head2 init

Adds the F<autoreference.js> file to the JavaScript files to send to the browser.

=cut

sub init {
    Jifty->web->add_javascript(qw/ autoreference.js /);
}

sub _auto_reference_autocompleter {
    my ($column, $from) = @_;

    my $reference = $column->refers_to;
    my $field     = $column->by || 'id';

    my $brief     = $reference->can('_brief_description') ? 
                        $reference->_brief_description : 'name';

    return sub {
        my $self  = shift;
        my $value = shift;

        my $collection = Jifty::Collection->new(
            record_class => $reference,
            current_user => $self->current_user,
        );

        $collection->unlimit;

        if (length $value) {
            $collection->limit(
                column   => $brief,
                value    => $value,
                operator => 'MATCHES',
                entry_aggregator => 'AND',
            );
        }

        $collection->limit(
            column   => $brief,
            value    => 'NULL',
            operator => 'IS NOT',
            entry_aggregator => 'AND',
        );

        $collection->limit(
            column   => $brief,
            value    => '',
            operator => '!=',
            entry_aggregator => 'AND',
        );

        $collection->columns('id', $brief);
        $collection->order_by(column => $brief);

        my @choices;
        if (!length $value && !$column->mandatory) {
            $collection->rows_per_page(9);
            push @choices, { label => _('- none -'), value => '' };
        }
        
        else {
            $collection->rows_per_page(10);
        }

        while (my $record = $collection->next) {
            push @choices, { 
                label => $record->brief_description.' [id:'.$record->id.']', 
                value => $record->id,
            };
        }

        return @choices;
    };
}

sub _auto_reference {
    my ($column, $from) = @_;

    my $name = $column->name;

    no strict 'refs';
    *{$from.'::autocomplete_'.$name} 
        = _auto_reference_autocompleter($column, $from);
}

use Jifty::DBI::Schema;
Jifty::DBI::Schema->register_types(
    AutoReference =>
        sub { _init_handler is \&_auto_reference, render_as 'Jifty::Plugin::AutoReference::Widget' } );

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
