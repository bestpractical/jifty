package Jifty::View::Declare::CoreTemplates;

use strict;
use warnings;

use Jifty::View::Declare -base;

=head1 NAME 

Jifty::View::Declare::CoreTemplates - Templates Jifty can't function without

=head1 DESCRIPTION

This library contains templates that Jifty can't function without:

=over

=item PubSub

=item Validate

=item Autocomplete

=item Canonicalize

=item YAML and XML webservice endpoints for core jifty functionality

=cut

=for later 

These templates are still in masonland. we're doign something wrong with escaping in them


template '__jifty/subs' => sub {
    my ($forever) = get(qw(forever)) || 1;

    Jifty->handler->apache->content_type("text/html; charset=utf-8");
    Jifty->handler->apache->headers_out->{'Pragma'}        = 'no-cache';
    Jifty->handler->apache->headers_out->{'Cache-control'} = 'no-cache';
    Jifty->handler->send_http_header;

    my $writer = XML::Writer->new;
    $writer->xmlDecl( "UTF-8", "yes" );

    my $begin = <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/2002/REC-xhtml1-20020801/DTD/xhtml1-strict.dtd">
<html><head><title></title></head>
END
    chomp $begin;

    if ($forever) {
        my $whitespace = " " x ( 1024 - length $begin );
        $begin =~ s/<body>$/$whitespace/s;
    }

    Jifty->web->out($begin);
    $writer->startTag("body");

    while (1) {
        my $sent = _write_subs_once($writer);
        flush STDOUT;
        last if ( $sent && !$forever );
        sleep 1;
    }
    $writer->endTag();
    return;

};

sub _write_subs_once {
    my $writer = shift;
    Jifty::Subs::Render->render(
        Jifty->web->session->id,
        sub {
            my ( $mode, $name, $content ) = @_;
            $writer->startTag( "pushfrag", mode => $mode );
            $writer->startTag( "fragment", id   => $name );
            $writer->dataElement( "content", $content );
            $writer->endTag();
            $writer->endTag();
        }
    );
}

template '__jifty/autocomplete.xml' => sub {

    # Note: the only point to this file is to set the content_type; the actual
    # behavior is accomplished inside the framework.  It will go away once we
    # have infrastructure for serving things of various content-types.
    Jifty->handler->apache->content_type('text/xml; charset=UTF-8');
    my $ref = Jifty->web->response->result('autocomplete')->content;
    my @options = @{ $ref->{'completions'} || [] };
    body {
        ul {
            foreach my $item (@options) {
                if ( !ref($item) ) {
                    li { $item };
                }
                elsif ( exists $item->{label} ) {
                    li {
                        with( class => "informal" ), span { $item->{label} };
                        with( class => "hidden_value" ),
                          span { $item->{value} };
                    };
                }
                else {
                    li { $item->{value} };
                }
            }
        };
    };
};


template '__jifty/validator.xml' => sub {
    Jifty->handler->apache->content_type('text/xml; charset=UTF-8');
    my $output = "";
    use XML::Writer;
    my $writer = XML::Writer->new( OUTPUT => \$output );
    $writer->xmlDecl( "UTF-8", "yes" );
    $writer->startTag("validation");
    for my $ra ( Jifty->web->request->actions ) {
        my $action = Jifty->web->new_action_from_request($ra);
        $writer->startTag( "validationaction", id => $action->register_name );
        for my $arg ( $action->argument_names ) {
            if ( not $action->arguments->{$arg}->{ajax_validates} ) {
                $writer->emptyTag( "ignored",
                    id => $action->error_div_id($arg) );
                $writer->emptyTag( "ignored",
                    id => $action->warning_div_id($arg) );
            }
            elsif ( not defined $action->argument_value($arg)
                    or length $action->argument_value($arg) == 0 )
            {
                $writer->emptyTag( "blank", id => $action->error_div_id($arg) );
                $writer->emptyTag( "blank",
                    id => $action->warning_div_id($arg) );
            }
            elsif ( $action->result->field_error($arg) ) {
                $writer->dataElement(
                    "error",
                    $action->result->field_error($arg),
                    id => $action->error_div_id($arg)
                );
                $writer->emptyTag( "ok", id => $action->warning_div_id($arg) );
            }
            elsif ( $action->result->field_warning($arg) ) {
                $writer->dataElement(
                    "warning",
                    $action->result->field_warning($arg),
                    id => $action->warning_div_id($arg)
                );
                $writer->emptyTag( "ok", id => $action->error_div_id($arg) );
            }
            else {
                $writer->emptyTag( "ok", id => $action->error_div_id($arg) );
                $writer->emptyTag( "ok", id => $action->warning_div_id($arg) );
            }
        }
        $writer->endTag();
        $writer->startTag( "canonicalizeaction", id => $action->register_name );
        for my $arg ( $action->argument_names ) {
            no warnings 'uninitialized';
            if ( $ra->arguments->{$arg} eq $action->argument_value($arg) ) {

                # if the value doesn' t change, it can be ignored .

# canonicalizers can change other parts of the action, so we want to send all changes
                $writer->emptyTag( "ignored",
                    name => $action->form_field_name($arg) );
            }
            elsif ( not defined $action->argument_value($arg)
                or length $action->argument_value($arg) == 0 )
            {
                $writer->emptyTag( "blank",
                    name => $action->form_field_name($arg) );
            }
            else {
                if ( $action->result->field_canonicalization_note($arg) ) {
                    $writer->dataElement(
                        "canonicalization_note",
                        $action->result->field_canonicalization_note($arg),
                        id => $action->canonicalization_note_div_id($arg)
                    );
                }
                $writer->dataElement(
                    "update",
                    $action->argument_value($arg),
                    name => $action->form_field_name($arg)
                );
            }
        }
        $writer->endTag();
    }
    $writer->endTag();
    Jifty->web->out($output);
};

=cut

template '__jifty/webservices/xml' => sub {
    Jifty->web->services->xml;
    return;
};
template '__jifty/webservices/json' => sub {
    Jifty->web->services->json;
    return;
};
template '__jifty/webservices/yaml' => sub {
    Jifty->web->services->yaml;
    return;
};

1;
