use warnings;
use strict;

package Jifty::Request::Mapper;

sub query_parameters {
    my $class = shift;

    my %parameters = @_;
    my %return;
    for my $key (keys %parameters) {
        if (ref $parameters{$key} eq "HASH") {
            my %mapping = %{$parameters{$key}};
            if ($mapping{result} or $mapping{result_of}) {
                # Pulling result of action
                my $action = $mapping{result} || $mapping{result_of};
                $action = $action->moniker if ref $action;
                my $name = $mapping{name} || $key;
                $return{"J:M-$key"} = "R-$action-$name";
            } elsif ($mapping{argument} or $mapping{argument_to}) {
                # Pulling argument of action
                my $action = $mapping{argument} || $mapping{argument_to};
                $action = $action->moniker if ref $action;
                my $name = $mapping{name} || $key;
                $return{"J:M-$key"} = "A-$action-$name";
            } else {
                warn "Don't know what to do with ".YAML::Dump(\%mapping);
            }
        } else {
            $return{$key} = $parameters{$key};
        }
    }

    return %return;
}


sub map {
    my $class = shift;

    my %args = (
                source      => undef,
                destination => undef,
                request     => Jifty->web->request,
                response    => Jifty->web->response,
                @_
               );

    return ($args{destination} => $args{source}) unless $args{destination} =~ /^J:M-(.*)/;

    my $destination = $1;

    if ($args{source} =~ /^A-([^-]+)-(.*)/) {
        return ($destination => $args{request}->action($1) ? $args{request}->action($1)->argument($2) : undef);
    } elsif ($args{source} =~ /^R-([^-]+)-(.*)/) {
        return ($destination => $args{response}->result($1) ? $args{response}->result($1)->content($2) : undef);
    } elsif ($args{source} =~ /^A-(.*)/) {
        return ($destination => $args{request}->arguments->{$1});
    } else {
        return ($destination => $args{source});
    }
    
}


1;
