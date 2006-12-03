use warnings;
use strict;

=head1 NAME

Jifty::Action::Record::Search

=head1 DESCRIPTION

The class is a base class for L<Jifty::Action>s that serve to provide
an interface to general searches through L<Jifty::Record> objects. To
use it, subclass it and override the C<record_class> method to return
the fully qualified name of the model to do searches over.

=cut

package Jifty::Action::Record::Search;
use base qw/Jifty::Action::Record/;

=head1 METHODS

=head2 arguments

Remove validators from arguments, as well as ``mandatory''
restrictions. Remove any arguments that render as password fields, or
refer to collections.

Generate additional search arguments for each field based on the
following criteria:

=over 4

=item C<text>, C<char> or C<varchar> fields

Create C<field>_contains and C<field>_lacks arguments

=item C<date>, or C<timestamp> fields

Create C<field>_before, C<field>_after, C<field>_since and
C<field>_until arguments.

=item C<integer>, C<float>, C<double>, C<decimal> or C<numeric> fields

Generate C<field>_lt, C<field>_gt, C<field>_le and C<field>_ge arguments, as
well as a C<field>_dwim field that accepts a prefixed comparison operator in
the search value, such as C<< >100 >> and C<< !100 >>.

=back

=cut

sub arguments {
    my $self = shift;
    return $self->_cached_arguments if $self->_cached_arguments;
    
    my $args = $self->SUPER::arguments;
    for my $field (keys %$args) {
        
        my $info = $args->{$field};

        my $column = $self->record->column($field);
        # First, modify the ``exact match'' search field (same name as
        # the original argument)

        delete $info->{validator};
        delete $info->{mandatory};

        if($info->{valid_values}) {
            my $valid_values = $info->{valid_values};

            local $@;
            $info->{valid_values} = $valid_values = (eval { [ @$valid_values ] } || [$valid_values]);

            # For radio display, display an "any" label as empty choices looks weird
            if (lc $info->{render_as} eq 'radio') {
                if (@$valid_values > 1) {
                    unshift @$valid_values, { display => _("(any)"), value => '' };
                    $info->{default_value} ||= '';
                }
                else {
                    # We've got only one choice anyway...
                    $info->{default_value} ||= $valid_values->[0];
                }
            }
            else {
                unshift @$valid_values, "";
            }
        }

        if(lc $info->{'render_as'} eq 'password') {
            delete $args->{$field};
            next;
        }

        warn "No column for: $field" unless($column);
        
        if(defined(my $refers_to = $column->refers_to)) {
            delete $args->{$field}
             if UNIVERSAL::isa($refers_to, 'Jifty::Collection');
        }
        # XXX TODO: What about booleans? Checkbox doesn't quite work,
        # since there are three choices: yes, no, either.

        # Magic _id refers_to columns
        next if($field =~ /^(.*)_id$/ && $self->record->column($1));

        my $label = $info->{label} || $field;
        $args->{"${field}_not"} = { %$info, label => _("%1 is not", $label) };
        my $type = lc($column->type);
        if($type =~ /(?:text|char)/) {
            $info->{render_as} = 'text';
            $args->{"${field}_contains"} = { %$info, label => _("%1 contains", $label) };
            $args->{"${field}_lacks"} = { %$info, label => _("%1 lacks", $label) };
        } elsif($type =~ /(?:date|time)/) {
            $args->{"${field}_after"} = { %$info, label => _("%1 after", $label) };
            $args->{"${field}_before"} = { %$info, label => _("%1 before", $label) };
            $args->{"${field}_since"} = { %$info, label => _("%1 since", $label) };
            $args->{"${field}_until"} = { %$info, label => _("%1 until", $label) };
        } elsif(    $type =~ /(?:int|float|double|decimal|numeric)/
                && !$column->refers_to) {
            $args->{"${field}_gt"} = { %$info, label => _("%1 greater than", $label) };
            $args->{"${field}_lt"} = { %$info, label => _("%1 less than", $label) };
            $args->{"${field}_ge"} = { %$info, label => _("%1 greater or equal to", $label) };
            $args->{"${field}_le"} = { %$info, label => _("%1 less or equal to", $label) };
            $args->{"${field}_dwim"} = { %$info, hints => _('!=>< allowed') };
        }
    }

    $args->{contains} = { type => 'text', label => _('Any field contains') };
    $args->{lacks} = { type => 'text', label => _('No field contains') };

    return $self->_cached_arguments($args);
}

=head2 take_action

Return a collection with the result of the search specified by the
given arguments.

We interpret a C<undef> argument as SQL C<NULL>, and ignore empty or
non-present arguments.

=cut

sub take_action {
    my $self = shift;

    my $collection = Jifty::Collection->new(
        record_class => $self->record_class,
        current_user => $self->record->current_user
    );

    $collection->unlimit;

    for my $field (grep {$self->has_argument($_)} $self->argument_names) {
        next if $field eq 'contains';
        my $value = $self->argument_value($field);
        
        my $column = $self->record->column($field);
        my $op = undef;
        
        if (!$column) {
            # If we don't have a column, this is a comparison or
            # substring search. Skip undef values for those, since
            # NULL makes no sense.
            next unless defined($value);
            next if $value =~ /^\s*$/;

            if ($field =~ m{^(.*)_([[:alpha:]]+)$}) {
                $field = $1;
                $op = $2;
                if($op eq 'not') {
                    $op = '!=';
                } elsif($op eq 'contains') {
                    $op = 'LIKE';
                    $value = "%$value%";
                } elsif($op eq 'lacks') {
                    $op = 'NOT LIKE';
                    $value = "%$value%";
                } elsif($op eq 'after' || $op eq 'gt') {
                    $op = '>';
                } elsif($op eq 'before' || $op eq 'lt') {
                    $op = '<';
                } elsif($op eq 'since' || $op eq 'ge') {
                    $op = '>=';
                } elsif($op eq 'until' || $op eq 'le') {
                    $op = '<=';
                } elsif($op eq 'dwim') {
                    $op = '=';
                    if (defined($value) and $value =~ s/^\s*([<>!=]{1,2})\s*//) {
                        $op = $1;
                        $op = '!=' if $op eq '!';
                        $op = '=' if $op eq '==';
                    }
                }
            } else {
                next;
            }
        }
        
        if(defined($value)) {
            next if $value =~ /^\s*$/;
           
            if ($op && $op =~ /^(?:!=|NOT LIKE)$/) {
                $collection->limit( column   => $field, value    => $value, operator => $op || "=", entry_aggregator => 'OR', $op ? (case_sensitive => 0) : (),);
                $collection->limit( column   => $field, value    => 'NULL', operator => 'IS');
            } else { 

            
            $collection->limit(
                column   => $field,
                value    => $value,
                operator => $op || "=",
                entry_aggregator => 'AND',
                $op ? (case_sensitive => 0) : (),
               );

            } 


        } else {
            $collection->limit(
                column   => $field,
                value    => 'NULL',
                operator => 'IS'
               );
        }
    }

    if($self->has_argument('contains')) {
        my $any = $self->argument_value('contains');
        for my $col ($self->record->columns) {
            if($col->type =~ /(?:text|varchar)/) {
                $collection->limit(column   => $col->name,
                                   value    => "%$any%",
                                   operator => 'LIKE',
                                   entry_aggregator => 'OR',
                                   subclause => 'contains');
            }
        }
    }

    $self->result->content(search => $collection);
    $self->result->success;
}

=head1 SEE ALSO

L<Jifty::Action::Record>, L<Jifty::Collection>

=cut

1;
