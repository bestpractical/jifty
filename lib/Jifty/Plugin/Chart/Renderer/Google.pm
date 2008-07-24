use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::Google;
use base qw/ Jifty::Plugin::Chart::Renderer /;

use URI::Escape qw(uri_escape);
use List::Util qw(max min);
use Scalar::Util qw(looks_like_number);

=head1 NAME

Jifty::Plugin::Chart::Renderer::Google - A chart renderer using Google Charts

=head1 DESCRIPTION

This is an alternate chart renderer used by the L<Jifty::Plugin::Chart> plugin. It works by rendering an <img> tag in the HTML output.

=head1 METHODS

=head2 render

Implemented the L<Jifty::Plugin::Chart::Renderer/render> method interface.

=cut

sub render {
    my $self = shift;
    my %args = (
        width     => 200,
        height    => 100,
        labels    => [],
        geoarea   => 'world',
        min_minus => 0,
        max_plus  => 0,
        @_
    );

    # Translations from generic type to Google charts types (incomplete)
    my %types = (
        trend                   => 'lc',
        lines                   => 'lxy',
        line                    => 'lxy',
        sparkline               => 'ls',
        horizontalbars          => 'bhg',
        bars                    => 'bvg',
        bar                     => 'bvg',
        stackedhorizontalbars   => 'bhs',
        stackedbars             => 'bvs',
        pie                     => 'p',
        pie3d                   => 'p3',
        venn                    => 'v',
        scatter                 => 's',
        points                  => 's',
        point                   => 's',
        map                     => 't',
        geo                     => 't',
    );

    # Make sure the type is ready to be used
    my $type = $types{ $args{type} } || undef;

    # Not a supported type
    if ( not defined $type ) {
        Jifty->log->warn("Unsupported chart type: $args{'type'}!");
        return;
    }

    # Kill the "px" unit
    $args{'width'} =~ s/px$//;
    $args{'height'} =~ s/px$//;

    # Check size and die if wrong
    for ( qw(width height) ) {
        if ( $type eq 't' ) {
            my $max = $_ eq 'width' ? 440 : 220;
            die "$_ over ${max}px" if $args{$_} > $max;
        } else {
            die "$_ over 1000px" if $args{$_} > 1000;
        }
    }

    # Check chart area
    die "Chart area over maximum allowed (300,000 for charts, 96,800 for maps)"
        if $args{'width'} * $args{'height'} > ( $type eq 't' ? 96800 : 300000 );

    if ( $type eq 't' ) {
        $args{'codes'} = shift @{ $args{'data'} };
        
        # Light blue for water
        $args{'bgcolor'} = "EAF7FE" if not defined $args{'bgcolor'};
    }

    # Set max/min value if we don't have one
    if ( not defined $args{'max_value'} or not defined $args{'min_value'} ) {
        my $max = 0;
        my $min = 0;

        for my $dataset ( @{ $args{'data'} } ) {
            if ( not defined $args{'max_value'} ) {
                my $lmax = max @$dataset;
                $max = $lmax if $lmax > $max;
            }
            if ( not defined $args{'min_value'} ) {
                my $lmin = min @$dataset;
                $min = $lmin if $lmin < $min;
            }
        }
        
        $args{'max_value'} = $max if not defined $args{'max_value'};
        $args{'min_value'} = $min if not defined $args{'min_value'};
    }

    # Build the base chart URL
    my $url = 'http://chart.apis.google.com/chart?';
    
    # Add the type
    $url .= "cht=$type";

    # Add the width - XXX TODO: we don't validate these yet
    $url .= "&chs=$args{'width'}x$args{'height'}";

    # Add the data (encoding it first)
    if ( $type eq 't' ) {
        # Map!
        $url .= "&chtm=$args{'geoarea'}";
        $url .= "&chld=" . join '', @{ $args{'codes'} };
        
        # We need to do simple encoding
        $url .= "&chd=s:" . $self->_simple_encode_data( $args{'max_value'}, @{$args{'data'}} );
    }
    else {
        my $min = $args{'min_value'} - $args{'min_minus'};
        my $max = $args{'max_value'} + $args{'max_plus'};

        # If it's a number, pass it through, otherwise replace it with a
        # number out of range to mark it as undefined
        my @data;
        for my $data ( @{$args{'data'}} ) {
            push @data, [map { looks_like_number($_) ? $_ : $max+42 } @$data];
        }

        # Let's do text encoding with data scaling
        $url .= "&chd=t:" . join '|', map { join ',', @$_ } @data;
        $url .= "&chds=$min,$max";
    }

    # Add the legend
    if ( $args{'legend'} ) {
        $url .= "&chdl="  . join '|', map { uri_escape($_) } @{ $args{'legend'} };
        $url .= "&chdlp=" . substr $args{'legend_position'}, 0, 1
            if $args{'legend_position'};
    }

    # Add any axes
    if ( $args{'axes'} ) {
        $url .= "&chxt=" . $args{'axes'};
        
        my $labels;
        my $index = 0;
        for my $labelset ( @{ $args{'labels'} } ) {
            $labels .= "$index:|" . join '|', map { uri_escape($_) } @$labelset
                if @$labelset;
            $index++;
        }
        $url .= "&chxl=$labels" if defined $labels;
    }

    # Add colors since Google::Chart sucks at it
    if ( defined $args{'colors'} ) {
        $url .= "&chco=" . join ',', @{ $args{'colors'} };
    }
    if ( defined $args{'bgcolor'} ) {
        $url .= "&chf=bg,s,$args{'bgcolor'}";
    }

    Jifty->web->out( qq{<img src="$url" />} );

    # Make sure we don't return anything that will get output
    return;
}

# Borrowed with slight modifications from Google::Chart::Data::SimpleEncoding
sub _simple_encode_data {
    my $self = shift;
    my $max  = shift;
    my $data = shift;

    my $result = '';
    my @map = ('A'..'Z', 'a'..'z', 0..9);
    for my $value ( @$data ) {
        if ( looks_like_number($value) ) {
            my $index = int($value / $max * (@map - 1));
            $index = 0 if $index < 0;
            $index = @map if $index > @map;
            $result .= $map[$index];
        } else {
            $result .= '_';
        }
    }
    return $result;
}

=head1 SEE ALSO

L<Jifty::Plugin::Chart>, L<Jifty::Plugin::Chart::Renderer>

=head1 AUTHOR

Thomas Sibley

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Best Practical Solutions, LLC

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
