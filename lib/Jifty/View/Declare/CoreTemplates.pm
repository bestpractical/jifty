package Jifty::View::Declare::CoreTemplates;

use strict;
use warnings;

use Jifty::View::Declare -base;

use Scalar::Defer;

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

=back

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

template '__jifty/webservices/xml' => sub {
    my $output = "";
    my $writer = XML::Writer->new(
        OUTPUT => \$output,
        UNSAFE => 1
    );
    $writer->xmlDecl( "UTF-8", "yes" );
    $writer->startTag("response");
    for my $f ( Jifty->web->request->fragments ) {

        # Set up the region stack
        local Jifty->web->{'region_stack'} = [];
        my @regions;
        do {
            push @regions, $f;
        } while ( $f = $f->parent );

        for $f ( reverse @regions ) {
            my $new =
              Jifty->web->get_region( join '-',
                grep { $_ } Jifty->web->qualified_region, $f->name );

            # Arguments can be complex mapped hash values.  Get their
            # real values by mapping.
            my %defaults = %{ $f->arguments || {} };
            for ( keys %defaults ) {
                my ( $key, $value ) = Jifty::Request::Mapper->map(
                    destination => $_,
                    source      => $defaults{$_}
                );
                delete $defaults{$_};
                $defaults{$key} = $value;
            }

            $new ||= Jifty::Web::PageRegion->new(
                name           => $f->name,
                path           => $f->path,
                region_wrapper => $f->wrapper,
                parent         => Jifty->web->current_region,
                defaults       => \%defaults,
            );
            $new->enter;
        }

        # Stuff the rendered region into the XML
        $writer->startTag( "fragment",
            id => Jifty->web->current_region->qualified_name );
        my %args = %{ Jifty->web->current_region->arguments };
        $writer->dataElement( "argument", $args{$_}, name => $_ )
          for sort keys %args;
        $writer->cdataElement( "content",
            Jifty->web->current_region->as_string );
        $writer->endTag();

        Jifty->web->current_region->exit while Jifty->web->current_region;
    }

    my %results = Jifty->web->response->results;
    for ( keys %results ) {
        $writer->startTag(
            "result",
            moniker => $_,
            class   => $results{$_}->action_class
        );
        $writer->dataElement( "success", $results{$_}->success );

        $writer->dataElement( "message", $results{$_}->message )
          if $results{$_}->message;
        $writer->dataElement( "error", $results{$_}->error )
          if $results{$_}->error;

        my %warnings = $results{$_}->field_warnings;
        my %errors   = $results{$_}->field_errors;
        my %fields;
        $fields{$_}++ for keys(%warnings), keys(%errors);
        for ( sort keys %fields ) {
            next unless $warnings{$_} or $errors{$_};
            $writer->startTag( "field", name => $_ );
            $writer->dataElement( "warning", $warnings{$_} )
              if $warnings{$_};
            $writer->dataElement( "error", $errors{$_} )
              if $errors{$_};
            $writer->endTag();
        }

        # XXX TODO: Hack because we don't have a good way to serialize
        # Jifty::DBI::Record's yet, which are technically circular data
        # structures at some level (current_user of a
        # current_user->user_object is itself)
        use Scalar::Util qw(blessed);
        my $content = $results{$_}->content;


        $content = _stripkids($content);
        use XML::Simple;
        $writer->raw(
            XML::Simple::XMLout(
                $content,
                NoAttr   => 1,
                RootName => "content",
                NoIndent => 1
            )
        ) if keys %{$content};

        $writer->endTag();
    }

    $writer->endTag();
    Jifty->handler->apache->content_type('text/xml; charset=UTF-8');

    # For some reason, this line is needed, lest we end up outputting ISO-8859-1 text
    utf8::decode($output);

    outs_raw($output);
};

        sub _stripkids {
            my $top = shift;
            if ( not ref $top ) { return $top }
            elsif (
                blessed($top)
                and (  $top->isa("Jifty::DBI::Record")
                    or $top->isa("Jifty::DBI::Collection") )
              )
            {
                return undef;
            }
            elsif ( ref $top eq 'HASH' ) {
                foreach my $item ( keys %$top ) {
                    $top->{$item} = _stripkids( $top->{$item} );
                }
            }
            elsif ( ref $top eq 'ARRAY' ) {
                for ( 0 .. $#{$top} ) {
                    $top->[$_] = _stripkids( $top->[$_] );
                }
            }
            return $top;
        }


template '__jifty/webservices/yaml' => sub {
    Jifty->handler->apache->content_type("text/x-yaml");
    outs( Jifty::YAML::Dump( { Jifty->web->response->results } ) );
};

=cut

1;
