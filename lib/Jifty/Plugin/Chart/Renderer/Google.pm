use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::Google;
use base qw/ Jifty::Plugin::Chart::Renderer /;

use URI::Escape qw(uri_escape);
use List::Util qw(max min sum);
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
        format    => '%0.2f',
        markers   => [],
        axis_styles => [],
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
    my $type = $types{ lc $args{type} } || undef;

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

        if ( $args{'type'} =~ /stacked/i ) {
            # Stacked bar charts are additive, so max / min take a little
            # more work to calculate
            my $size = @{ $args{'data'}->[0] } - 1;
            for my $index ( 0 .. $size ) {
                my @stack = grep { defined } map { $_->[$index] } @{ $args{'data'} };

                if ( not defined $args{'max_value'} ) {
                    # Add all of the positive numbers
                    my $lmax = sum grep { $_ > 0 } @stack;
                    $max = $lmax if defined $lmax and $lmax > $max;
                }
                if ( not defined $args{'min_value'} ) {
                    # Add all of the negative numbers
                    my $lmin = sum grep { $_ < 0 } @stack;
                    $min = $lmin if defined $lmin and $lmin < $min;
                }
            }
        }
        else {
            # Everything else, simply find the largest and smallest value in
            # any of the datasets
            for my $dataset ( @{ $args{'data'} } ) {
                if ( not defined $args{'max_value'} ) {
                    my $lmax = max grep { defined } @$dataset;
                    $max = $lmax if $lmax > $max;
                }
                if ( not defined $args{'min_value'} ) {
                    my $lmin = min grep { defined } @$dataset;
                    $min = $lmin if $lmin < $min;
                }
            }
        }
        
        $args{'max_value'} = $max if not defined $args{'max_value'};
        $args{'min_value'} = $min if not defined $args{'min_value'};
    }

    # Build the base chart URL
    my $url = 'http://chart.apis.google.com/chart?';
    
    # Add the type
    $url .= "cht=$type";

    # Add the width
    $url .= "&chs=$args{'width'}x$args{'height'}";

    # Format the data
    unless ( not defined $args{'format'} ) {
        for my $set ( @{$args{'data'}} ) {
            @$set = map {
                        looks_like_number($_)
                            ? sprintf $args{'format'}, $_
                            : $_
                    } @$set;
        }
    }

    # Add the data (encoding it first)
    if ( $type eq 't' ) {
        # Map!
        $url .= "&chtm=$args{'geoarea'}";
        $url .= "&chld=" . join '', @{ $args{'codes'} };
        
        # We need to do simple encoding
        $url .= "&chd=s:" . $self->_simple_encode_data( $args{'max_value'}, @{$args{'data'}} );
    }
    else {
        # Deal with out of range horizontal markers here by fixing our range
        if ( @{ $args{'markers'} } ) {
            for my $marker ( grep { $_->{'type'} eq 'h' } @{$args{'markers'}} ) {
                $args{'max_value'} = $marker->{'position'}
                    if $marker->{'position'} > $args{'max_value'};
                
                $args{'min_value'} = $marker->{'position'}
                    if $marker->{'position'} < $args{'min_value'};
            }
        }

        # If we want to add/subtract a percentage of the max/min, then
        # calculate it now
        for my $limit (qw( min max )) {
            my $key = $limit . "_" . ($limit eq 'min' ? 'minus' : 'plus');
            if ( $args{$key} =~ s/\%$// ) {
                $args{$key} = ($args{$key} / 100) * abs($args{ $limit."_value" });
            }
        }

        my $min = $args{'min_value'} - $args{'min_minus'};
        my $max = $args{'max_value'} + $args{'max_plus'};
        
        $args{'calculated_min'} = $min;
        $args{'calculated_max'} = $max;

        # Format the min and max for use a few lines down
        unless ( not defined $args{'format'} ) {
            $min = sprintf $args{'format'}, $min;
            $max = sprintf $args{'format'}, $max;
        }

        # If it's a number, pass it through, otherwise replace it with a
        # number out of range to mark it as undefined
        my @data;
        for my $data ( @{$args{'data'}} ) {
            push @data, [map { looks_like_number($_) ? $_ : $min-42 } @$data];
        }

        # Let's do text encoding with data scaling
        $url .= "&chd=t:" . join '|', map { join ',', @$_ } @data;
        $url .= "&chds=$min,$max";
    }

    # Add a title
    if ( defined $args{'title'} ) {
        $args{'title'} =~ tr/\n/|/;
        $url .= "&chtt=" . uri_escape( $args{'title'} );
    }

    # Add the legend
    if ( $args{'legend'} ) {
        my $key = $args{'type'} =~ /pie/i ? 'chl' : 'chdl';

        $url .= "&$key="  . join '|', map { uri_escape($_) } @{ $args{'legend'} };
        $url .= "&chdlp=" . substr $args{'legend_position'}, 0, 1
            if $args{'legend_position'};
    }

    # Add any axes
    if ( $args{'axes'} ) {
        $url .= "&chxt=" . $args{'axes'};

        if ( defined $args{'labels'} ) {
            my @labels;
            my @ranges;
            my $index = 0;
            for my $labelset ( @{ $args{'labels'} } ) {
                if ( ref $labelset eq 'ARRAY' and @$labelset ) {
                    push @labels, "$index:|" . join '|', map { uri_escape($_) } @$labelset;
                }
                elsif ( not ref $labelset and $labelset eq 'RANGE' ) {
                    push @ranges, sprintf "%d,$args{'format'},$args{'format'}",
                                           $index, $args{'calculated_min'}, $args{'calculated_max'};
                }
                $index++;
            }
            
            my @styles;
            $index = 0;
            for my $style ( @{ $args{'axis_styles'} } ) {
                if ( ref $style eq 'ARRAY' and @$style ) {
                    push @styles, join ',', $index, @$style;
                }
                $index++;
            }

            $url .= "&chxl=" . join '|', @labels if @labels;
            $url .= "&chxr=" . join '|', @ranges if @ranges;
            $url .= "&chxs=" . join '|', @styles if @styles;
        }
    }

    # Add colors
    if ( defined $args{'colors'} ) {
        $url .= "&chco=" . join ',', @{ $args{'colors'} };
    }
    if ( defined $args{'bgcolor'} ) {
        $url .= "&chf=bg,s,$args{'bgcolor'}";
    }

    # Add bar widths for bar charts
    if ( $args{'type'} =~ /bar/i ) {
        $url .= "&chbh=" . join ',', @{ $args{'bar_width'} };
    }

    # Add shape markers
    if ( @{ $args{'markers'} } ) {
        my @markers;
        for my $data ( @{$args{'markers'}} ) {
            my %marker = (
                type     => 'x',
                color    => '000000',
                dataset  => 0,
                position => 0,
                size     => 5,
                priority => 0,
                %$data,
            );

            # Calculate where the position should be for horizontal lines
            if ( $marker{'type'} eq 'h' ) {
                $marker{'position'} /= abs( $args{'calculated_max'} - $args{'calculated_min'} );
            }
            # Fix text type
            elsif ( $marker{'type'} eq 't' ) {
                $marker{'type'} .= uri_escape( $marker{'text'} );
            }

            # Format the position
            $marker{'position'} = sprintf $args{'format'}, $marker{'position'};

            push @markers, join(',', @marker{qw( type color dataset position size priority )});
        }
        $url .= "&chm=" . join '|', @markers if @markers;
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
