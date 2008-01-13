use strict;
use warnings;

=head1 NAME

TestApp::JiftyJS::Action::Play

=cut

package TestApp::JiftyJS::Action::Play;
use base qw/TestApp::JiftyJS::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param vanilla => type is 'text';

    param mood =>
        type is 'text',
        ajax validates,
        valid are qw(happy angry normal);

    param flavor =>
        autocompleter is \&autocomplete_flavor,
        type is 'text';

    param tags =>
        type is 'text',
        ajax canonicalizes;
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    $self->report_success if not $self->result->failure;
    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message('Success');
}

sub canonicalize_tags {
    my ($self, $value) = @_;
    my $v = lc($value);
    $v =~ s/\s+/ /g;
    $v =~ s/^\s*//g;
    $v =~ s/\s*$//g;

    return $v;
}

sub autocomplete_flavor {
    my ($self, $value) = @_;
    return grep {
        $_ =~ /$value/i;
    } sort qw( berry vanilla caramel caracara honey miso blueberry strawberry );

}

1;

