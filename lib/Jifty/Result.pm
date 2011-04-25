use warnings;
use strict;

package Jifty::Result;

=head1 NAME

Jifty::Result - Outcome of running a L<Jifty::Action>

=head1 DESCRIPTION

C<Jifty::Result> encapsulates the outcome of running a
L<Jifty::Action>.  Results are also stored on the framework's
L<Jifty::Response> object.

=cut



use base qw/Jifty::Object Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw(failure action_class message _content));


=head2 new

Construct a new action result.  This is done automatically when the
action is created, and can be accessed via the
L<Jifty::Action/result>.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->failure(0);
    $self->_content({});

    return $self;
}

=head2 failure [BOOL]

Gets or sets if the action succeeded or failed.

=head2 success [BOOL]

Gets or sets if the action succeeded or failed -- this is an
alternate interface from C<failure> but has the same effect.

=cut

sub success {
    my $self = shift;
    return 0 if $self->failure(map {not $_} @_);
    return 1;
}

=head2 action_class [MESSAGE]

Returns the class for the action that this result came from.

=head2 message [MESSAGE]

Gets or sets the action's response message.  This is an informational
textual description of the outcome of the action.

=head2 error [ERROR]

Gets or sets the action's error response.  This is an informational
textual description of what went wrong with the action, overall.  This
also automatically sets the result to be a L</failure>.

=cut

sub error {
    my $self = shift;
    
    $self->failure(1) if @_ and $_[0];
    $self->{error} = shift if @_;
    return $self->{error};
}

=head2 field_error FIELD [ERROR] [OPTIONS]

Gets or sets the error string for a specific field on the action.
This also automatically sets the result to be a failure.  C<OPTIONS>
is an optional set of key-value pairs; the only currently supported
option is C<force>, which sets the L</ajax_force_validate> for this
field.

=cut

sub field_error {
    my $self = shift;
    my $field = shift;

    $self->failure(1) if @_ and $_[0];
    $self->{field_errors}{ $field } = shift if @_;

    my %args = @_;
    $self->{ajax_force_validate}{ $field } = $args{force} if exists $args{force};

    return $self->{field_errors}{ $field };
}

=head2 field_errors

Returns a hash which maps L<argument|Jifty::Manual::Glossary/argument>
name to error.

=cut

sub field_errors {
    my $self = shift;
    return %{$self->{field_errors} || {}};
}

=head2 field_warning FIELD [WARNING] [OPTIONS]

Gets or sets the warning string for a specific field on the
action. C<OPTIONS> is an optional set of key-value pairs; the only
currently supported option is C<force>, which sets the
L</ajax_force_validate> for this field.

=cut

sub field_warning {
    my $self = shift;
    my $field = shift;

    $self->{field_warnings}{ $field } = shift if @_;

    my %args = @_;
    $self->{ajax_force_validate}{ $field } = $args{force} if exists $args{force};

    return $self->{field_warnings}{ $field };
}

=head2 field_warnings

Returns a hash which maps L<argument|Jifty::Manual::Glossary/argument>
name to warning.

=cut

sub field_warnings {
    my $self = shift;
    return %{$self->{field_warnings} || {}};
}

=head2 ajax_force_validate FIELD [VALUE]

Gets or sets the flag which determines if warnings and errors are set
using ajax validation, even if the field is empty.  By default,
validation warnings and errors are I<not> shown for empty fields, as
yelling to users about mandatory fields they've not gotten to yet is
poor form.  You can use this method to force ajax errors to show even
on empty fields.

=cut

sub ajax_force_validate {
    my $self = shift;
    my $field = shift;
    $self->{ajax_force_validate}{ $field } = shift if @_;
    return $self->{ajax_force_validate}{$field};
}

=head2 field_canonicalization_note FIELD [NOTE]

Gets or sets a canonicalization note for a specific field on the action.

=cut

sub field_canonicalization_note {
    my $self = shift;
    my $field = shift;

    $self->{field_canonicalization_notes}{ $field } = shift if @_;
    return $self->{field_canonicalization_notes}{ $field };
}

=head2 field_canonicalization_notes

Returns a hash which maps L<argument|Jifty::Manual::Glossary/argument>
name to canonicalization notes.

=cut

sub field_canonicalization_notes {
    my $self = shift;
    return %{$self->{field_canonicalization_notes} || {}};
}

=head2 content [KEY [, VALUE]]

Gets or sets the content C<KEY>.  This is used when actions need to
return values.  If not C<KEY> is passed, it returns an anonymous hash
of all of the C<KEY> and C<VALUE> pairs.

=cut

sub content {
    my $self = shift;

    return $self->_content unless @_;

    my $key = shift;
    $self->_content->{$key} = shift if @_;
    return $self->_content->{$key};
}

=head2 as_hash

This returns the results as a hash to be given directly to the end user
(usually via REST or webservices). The difference between
C<< $result->as_hash >> and C<%$result> is that the latter will expand
everything as deeply as possible. The former won't inflate C<refers_to>
columns, among other things.

=cut

sub as_hash {
    my $self = shift;

    my $out = {
        success        => $self->success,
        failure        => $self->failure,
        action_class   => $self->action_class,
        message        => $self->message,
        error          => $self->error,
        field_errors   => { $self->field_errors },
        field_warnings => { $self->field_warnings },
        content        => $self->_recurse_object_to_data($self->content),
    };

    for (keys %{$out->{field_errors}}) {
        delete $out->{field_errors}->{$_} unless $out->{field_errors}->{$_};
    }
    for (keys %{$out->{field_warnings}}) {
        delete $out->{field_warnings}->{$_} unless $out->{field_warnings}->{$_};
    }

    return $out;
}

sub _recurse_object_to_data {
    my $self = shift;
    my $o = shift;

    return $o if !ref($o);

    if (ref($o) eq 'ARRAY') {
        return [ map { $self->_recurse_object_to_data($_) } @$o ];
    }
    elsif (ref($o) eq 'HASH') {
        my %h;
        $h{$_} = $self->_recurse_object_to_data($o->{$_}) for keys %$o;
        return \%h;
    }

    return $self->_object_to_data($o);
}

sub _object_to_data {
    my $self = shift;
    my $o = shift;

    if ($o->can('jifty_serialize_format')) {
        return $o->jifty_serialize_format($self);
    }

    # As the last resort, return the object itself and expect the
    # $accept-specific renderer to format the object as e.g. YAML or JSON data.
    return $o;
}

1;
