package Jifty::Web::Services;

use strict;
use warnings;

use base qw(Jifty::Object);

use Scalar::Util qw(blessed);
use XML::Simple;
use Jifty::JSON;
use Jifty::YAML;

sub new {
    my $proto = shift;
    return bless {}, ref($proto)||$proto;
}

sub _results {
    my $self = shift;

    my %results = Jifty->web->response->results;
    for (values %results) {
        $_ = $_->as_hash;

        # backwards compatibility :(
        $_->{_content} = delete $_->{content};
    }
    return \%results;
}

sub json {
    my $self = shift;
    Jifty->handler->apache->content_type("text/x-json");
    Jifty->web->out( Jifty::JSON::objToJson( $self->_results ) );
}

sub yaml {
    my $self = shift;
    Jifty->handler->apache->content_type("text/x-yaml");
    Jifty->web->out( Jifty::YAML::Dump( $self->_results ) );
}

sub xml {
    my $self = shift;

    Jifty->handler->apache->content_type('text/xml; charset=UTF-8');

    my $output = "";
    my $writer = XML::Writer->new( OUTPUT => \$output, UNSAFE => 1 );
    $writer->xmlDecl( "UTF-8", "yes" );
    $writer->startTag("response");

    if (my $ext = Jifty->web->request->argument('_webservice_external_redirect')) {
        $writer->startTag("redirect");
        $writer->cdataElement(url=> $ext);
        $writer->endTag;
        $writer->endTag;
        Jifty->web->out($output);
        return;
    }

    FRAGMENT:
    for my $fragment ( Jifty->web->request->fragments ) {
        # Set up the form if need be
        Jifty->web->form->_init;
        Jifty->web->form->is_open(1) if $fragment->in_form;

        # Set up the region stack
        local Jifty->web->{'region_stack'} = [];
        my @regions;
        do {
            push @regions, $fragment;
        } while ($fragment = $fragment->parent);

        for my $current (reverse @regions) {
            my $new = Jifty->web->get_region( join '-', grep {$_} Jifty->web->qualified_region, $current->name );

            # Arguments can be complex mapped hash values.  Get their
            # real values by mapping.
            my %defaults = %{$current->arguments || {}};
            for (keys %defaults) {
                my ($key, $value) = Jifty::Request::Mapper->map(destination => $_, source => $defaults{$_});
                delete $defaults{$_};
                $defaults{$key} = $value;
            }

            $new ||= Jifty::Web::PageRegion->new(
                name           => $current->name,
                path           => URI::Escape::uri_unescape($current->path),
                region_wrapper => $current->wrapper,
                parent         => Jifty->web->current_region,
                defaults       => \%defaults,
            );

            # It's possible that the pageregion creation could fail -- no
            # name, for instance.  In that case, bail on this fragment.
            next FRAGMENT unless $new;

            $new->enter;
        }

        # Stuff the rendered region into the XML
        my $current_region = Jifty->web->current_region;
        $writer->startTag( "fragment", id => $current_region->qualified_name );
        my $args = $current_region->arguments;
        $writer->dataElement( "argument", $args->{$_}, name => $_) for sort keys %$args;
        if (Jifty->config->framework('ClientTemplate') && $current_region->client_cacheable) {
            $writer->cdataElement( "cacheable", $current_region->client_cache_content, type => $current_region->client_cacheable );
        }
        $writer->cdataElement( "content", $current_region->as_string );
        $writer->endTag();

        # Clean up region stack and form
        Jifty->web->current_region->exit while Jifty->web->current_region;
        Jifty->web->form->is_open(0);
    }

    my %results = Jifty->web->response->results;
    for (keys %results) {
        $writer->startTag("result", moniker => $_, class => $results{$_}->action_class);
        $writer->dataElement("success", $results{$_}->success);

        $writer->dataElement("message", $results{$_}->message) if $results{$_}->message;
        $writer->dataElement("error", $results{$_}->error) if $results{$_}->error;

        my %warnings = $results{$_}->field_warnings;
        my %errors   = $results{$_}->field_errors;
        my %fields; $fields{$_}++ for keys(%warnings), keys(%errors);
        for (sort keys %fields) {
            next unless $warnings{$_} or $errors{$_};
            $writer->startTag("field", name => $_);
            $writer->dataElement("warning", $warnings{$_}) if $warnings{$_};
            $writer->dataElement("error", $errors{$_}) if $errors{$_};
            $writer->endTag();
        }

        # XXX TODO: Hack because we don't have a good way to serialize
        # Jifty::DBI::Record's yet, which are technically circular data
        # structures at some level (current_user of a
        # current_user->user_object is itself)
        my $content = _stripkids($results{$_}->content);
        $writer->raw(XML::Simple::XMLout($content, NoAttr => 1, RootName => "content", NoIndent => 1))
          if keys %{$content};

        $writer->endTag();
    }

    $writer->endTag();
    Jifty->web->out($output);
}

sub _stripkids {
    my $top = shift;
    if ( not ref $top ) {
        return $top
    }
    elsif (
        blessed($top)
        and (  $top->isa("Jifty::DBI::Record")
            or $top->isa("Jifty::DBI::Collection") )
        )
    {
        return undef;
    }
    elsif ( ref $top eq 'HASH' ) {
        $top->{$_} = _stripkids( $top->{$_} ) foreach keys %$top;
    }
    elsif ( ref $top eq 'ARRAY' ) {
        push @$top, _stripkids( $_ ) foreach splice @$top;
    }
    return $top;
}

1;
