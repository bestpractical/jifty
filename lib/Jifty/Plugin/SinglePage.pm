use strict;
use warnings;

package Jifty::Plugin::SinglePage;
use base qw/Jifty::Plugin/;

sub init {
    my $self = shift;
    Jifty::Web::Form::Clickable->add_trigger( before_new => \&_sp_link);
}

sub _sp_link {
    my ($self, $args) = @_;
    if (my $url = delete $args->{'url'}) {
	# XXX mind the existing onclick
	warn 'ooops got original onclick'. Dumper($args->{onclick}) if $args->{onclick};
	$args->{onclick}=  { region       => "__page", replace_with => $url,
			     args => delete $args->{parameters} };
    }
}


1;
