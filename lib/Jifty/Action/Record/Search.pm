use warnings;
use strict;

=head1 NAME

Jifty::Action::Record::Search - Automagic search action

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

sub class_arguments {
    my $self = shift;

    # Iterate through all the arguments setup by Jifty::Action::Record
    my $args = $self->SUPER::class_arguments;
    for my $field (keys %$args) {
        # Figure out what information we know about the field
        my $info = $args->{$field};
        my $column = $self->record->column($field);

        # We don't care about validation and mandatories on search
        delete $info->{validator};
        delete $info->{mandatory};

        # If the column has a set of valid values, deal with those
        if ($info->{valid_values}) {
            my $valid_values = $info->{valid_values};

            # Canonicalize the valid values
            local $@;
            $info->{valid_values} = $valid_values = (eval { [ @$valid_values ] } || [$valid_values]);

            # For radio display, display an "any" label (empty looks weird)
            if (defined $info->{render_as} and lc $info->{render_as} eq 'radio') {
                if (@$valid_values > 1) {
                    unshift @$valid_values, { display => _("(any)"), value => '' };
                    $info->{default_value} ||= '';
                }
                else {
                    # We've got only one choice anyway...
                    $info->{default_value} ||= $valid_values->[0];
                }
            }

            # If not radio, add a blank options
            else {
                unshift @$valid_values, "";
            }
        }

        # You can't search passwords, so remove the fields
        if(defined $info->{'render_as'} and lc $info->{'render_as'} eq 'password') {
            delete $args->{$field};
            next;
        }

        # Warn if we have a search field without an actual column
        warn "No column for: $field" unless($column);
        
        # Drop out X-to-many columns from the search
        if(defined(my $refers_to = $column->refers_to)) {
            delete $args->{$field}
             if UNIVERSAL::isa($refers_to, 'Jifty::Collection');
        }
        if ($info->{container}) {
            delete $args->{$field};
            next;
        }

        # XXX TODO: What about booleans? Checkbox doesn't quite work,
        # since there are three choices: yes, no, either.

        # Magic _id refers_to columns
        next if($field =~ /^(.*)_id$/ && $self->record->column($1));

        # Setup the field label for the comparison operator selection
        my $label = $info->{label} || $field;

        # Add the "X is not" operator
        $args->{"${field}_not"} = { %$info, label => _("%1 is not", $label) };

        # The operators available depend on the type
        my $type = lc($column->type);

        # Add operators available for text fields
        if($type =~ /(?:text|char)/) {

            # Show a text entry box (rather than a textarea)
            $info->{render_as} = 'text';

            # Add the "X contains" operator
            $args->{"${field}_contains"} = { %$info, label => _("%1 contains", $label) };

            # Add the "X lacks" operator (i.e., opposite of "X contains")
            $args->{"${field}_lacks"} = { %$info, label => _("%1 lacks", $label) };
        } 
        
        # Handle date, datetime, time, and timestamp fields
        elsif($type =~ /(?:date|time)/) {

            # Add the "X after" date/time operation
            $args->{"${field}_after"} = { %$info, label => _("%1 after", $label) };

            # Add the "X before" date/time operation
            $args->{"${field}_before"} = { %$info, label => _("%1 before", $label) };

            # Add the "X since" date/time operation
            $args->{"${field}_since"} = { %$info, label => _("%1 since", $label) };

            # Add the "X until" date/time operation
            $args->{"${field}_until"} = { %$info, label => _("%1 until", $label) };
        } 
        
        # Handle number fields
        elsif(    $type =~ /(?:int|float|double|decimal|numeric)/
                && !$column->refers_to) {

            # Add the "X greater than" operation
            $args->{"${field}_gt"} = { %$info, label => _("%1 greater than", $label) };

            # Add the "X less than" operation
            $args->{"${field}_lt"} = { %$info, label => _("%1 less than", $label) };

            # Add the "X greater than or equal to" operation
            $args->{"${field}_ge"} = { %$info, label => _("%1 greater or equal to", $label) };

            # Add the "X less than or equal to" operation
            $args->{"${field}_le"} = { %$info, label => _("%1 less or equal to", $label) };

            # Add the "X is whatever the heck I say it is" operation
            $args->{"${field}_dwim"} = { %$info, hints => _('!=>< allowed') };
        }
    }

    # Add generic contains/lacks search boxes for all fields
    $args->{contains} = { type => 'text', label => _('Any field contains') };
    $args->{lacks} = { type => 'text', label => _('No field contains') };

    # Cache the results so we don't have to do THAT again
    return $args;
}

=head2 take_action

Return a collection with the result of the search specified by the
given arguments.

We interpret a C<undef> argument as SQL C<NULL>, and ignore empty or
non-present arguments.

=cut

sub take_action {
    my $self = shift;

    # Create a generic collection for our record class
    my $collection = $self->record_class->collection_class->new(
        record_class => $self->record_class,
        current_user => $self->record->current_user
    );

    # Start with an unlimited collection
    $collection->find_all_rows;

    # For each field, process the limits
    for my $field (grep {$self->has_argument($_)} $self->argument_names) {

        # We process contains last, skip it here
        next if $field eq 'contains';

        # Get the value set on the field
        my $value = $self->argument_value($field);
        
        # Load the column this field belongs to
        my $column = $self->record->column($field);
        my $op = undef;
        
        # A comparison or substring search rather than an exact match?
        if (!$column) {

            # If we don't have a column, this is a comparison or
            # substring search. Skip undef values for those, since
            # NULL makes no sense.
            next unless defined($value);
            next if $value =~ /^\s*$/;

            # Decode the field_op name
            if ($field =~ m{^(.*)_([[:alpha:]]+)$}) {
                $field = $1;
                $op = $2;

                # Convert each operator into limit operators
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
            } 
            
            # Doesn't look like a field_op, skip it
            else {
                next;
            }
        }
        
        # Now, add the limit if we have a value set
        if (defined($value)) {
            next if $value =~ /^\s*$/; # skip blank values!
           
            # Allow != and NOT LIKE to match NULL columns
            if ($op && $op =~ /^(?:!=|NOT LIKE)$/) {
                $collection->limit( 
                    column   => $field, 
                    value    => $value, 
                    operator => $op,
                    entry_aggregator => 'OR', 
                    case_sensitive => 0,
                );
                $collection->limit( 
                    column   => $field, 
                    value    => 'NULL', 
                    operator => 'IS',
                );
            } 
            
            # For any others, just the facts please
            else { 
                $collection->limit(
                    column   => $field,
                    value    => $value,
                    operator => $op || "=",
                    entry_aggregator => 'AND',
                    $op ? (case_sensitive => 0) : (),
                );
            } 
        } 

        # The value is not defined at all, so expect a NULL
        else {
            $collection->limit(
                column   => $field,
                value    => 'NULL',
                operator => 'IS'
            );
        }
    }

    # Handle the general contains last
    if($self->has_argument('contains')) {

        # See if any column contains the text described
        my $any = $self->argument_value('contains');
        if (length $any) {
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
    }

    # Add the limited collection to the results
    $self->result->content(search => $collection);
    $self->result->success;
}

=head1 SEE ALSO

L<Jifty::Action::Record>, L<Jifty::Collection>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
