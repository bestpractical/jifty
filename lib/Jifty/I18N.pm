package Jifty::I18N;

use strict;
use base 'Exporter';

our @EXPORT = 'loc';

        require Locale::Maketext::Simple;
        Locale::Maketext::Simple->import(
            Subclass    => '',
            Path            => substr(__FILE__, 0, -3),
            Style           => 'gettext',
            Encoding    => 'locale',
        );

1;
