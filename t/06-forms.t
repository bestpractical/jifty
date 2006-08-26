use warnings;
use strict;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 'jiftyapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use Jifty::Test tests => 11;

use_ok ('Jifty::Web::Form::Field');

can_ok('Jifty::Web::Form::Field', 'new');
can_ok('Jifty::Web::Form::Field', 'name');

my $field = Jifty::Web::Form::Field->new();


# Form::Fields don't work without a framework
is($field->name, undef);
ok($field->name('Jesse'));
is($field->name, 'Jesse');

is($field->class, '');
is($field->class('basic'),'basic');
is($field->class(),'basic');
is($field->name, 'Jesse');

is ($field->type, 'text', "type defaults to text");
