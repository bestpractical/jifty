use warnings;
use strict;
use Jifty::Test tests => 24;

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

# Test render_XXX methods:
SKIP: {
    eval {
        require Test::MockObject;
        require Test::MockModule;
    };
    skip "Test::MockObject or Test::MockModule required",
        13 if $@;

    my $out; # buf to store mason outputs

    # mock up an instance of Jifty::Result
    my $result = Test::MockObject->new;
    $result->set_series('field_error', 'error: invalid email address', '');
    $result->set_series('field_warning', 'warning: password too short', '');
    $result->set_series('field_canonicalization_note', "I've changed it!", '');

    # mock up an instance of Jifty::Action
    my $action = Test::MockObject->new;
    $action->set_always('result', $result);
    $action->set_always('form_field_name', 'search_keys');
    $action->set_series('error_div_id', 'FOO-error', 'no-error');
    $action->set_series('warning_div_id', 'BAR-warning', 'no-warning');
    $action->set_series('canonicalization_note_div_id', 'canonicalize', 'nothing');

    # mock up an instance of Jifty::Web
    my $web = Test::MockObject->new;
    $web->mock('out', sub {
        shift;
        if (@_) { $out .= "@_" }
        $out;
    });
    $web->set_always('serial', 32);

    # mock up the Jifty package
    my $module = new Test::MockModule('Jifty');
    $module->mock('web', sub { $web });

    # Test nonempty render_XXX:

    $field = Jifty::Web::Form::Field->new();
    $field->action($action);
    $field->class('blah');
    $field->name('agentz');

    # Test render_lable:
    $field->label('Audrey Tang');
    $out = '';
    $field->render_label;
    is $out, qq{<label class="label text blah argument-agentz" for="search_keys-32">}.
        qq{Audrey Tang</label>\n};

    # Test render_hints:
    $field->hints('She is here!');
    $out = '';
    $field->render_hints;
    is $out, qq{<span class="hints text blah argument-agentz">She is here!</span>\n};

    # Test render_errors:
    $out = '';
    $field->render_errors;
    is $out, qq{<span class="error text blah argument-agentz" id="FOO-error">}.
        qq{error: invalid email address</span>\n};

    # Test render_warnings:
    $out = '';
    $field->render_warnings;
    is $out, qq{<span class="warning text blah argument-agentz" id="BAR-warning">}.
        qq{warning: password too short</span>\n};

    # Test render_canonicalization_notes:
    $out = '';
    $field->render_canonicalization_notes;
    is $out, qq{<span class="canonicalization_note text blah argument-agentz" }.
        qq{id="canonicalize">I've changed it!</span>\n};

    # Test render_preamble:
    $out = '';
    $field->preamble("preamble's here!");
    $field->render_preamble;
    is $out, qq{<span class="preamble text blah argument-agentz">}.
        qq{preamble's here!</span>\n};

    # Test empty labels:
    $field->name('yichun');
    $field->label('');
    $field->class('');
    $out = '';
    $field->render_label;
    is $out, qq{<label class="label text  argument-yichun" for="search_keys-32"></label>\n};

    # Test default labels:
    $field->name('yichun');
    $field->label(undef);
    $field->class('hey');
    $out = '';
    $field->render_label;
    is $out, qq{<label class="label text hey argument-yichun" for="search_keys-32">}.
        qq{yichun</label>\n};

    # Test empty hints:
    $field->name('xunxin');
    $field->class('ujs');
    $field->hints('');
    $out = '';
    $field->render_hints;
    is $out, qq{<span class="hints text ujs argument-xunxin"></span>\n};

    # Test empty errors:
    $out = '';
    $field->render_errors;
    is $out, qq{<span class="error text ujs argument-xunxin" id="no-error"></span>\n};

    # Test empty warnings:
    $out = '';
    $field->render_warnings;
    is $out, qq{<span class="warning text ujs argument-xunxin" id="no-warning"></span>\n};

    # Test empty canonicalization note:
    $out = '';
    $field->render_canonicalization_notes;
    is $out, qq{<span class="canonicalization_note text ujs argument-xunxin" }.
        qq{id="nothing"></span>\n};

    # Test empty preambles:
    $out = '';
    $field->preamble("");
    $field->render_preamble;
    is $out, qq{<span class="preamble text ujs argument-xunxin"></span>\n};
}
