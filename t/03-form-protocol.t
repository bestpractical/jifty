use t::Jifty;

run_is_deeply;

__DATA__
=== one action
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:ACTIONS: mymoniker
template_arguments: {}
fragments: {}
=== two actions
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoSomething
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker!second
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A-second: DoSomething
  J:A:F-id-second: 42
  J:A:F-something-second: bla
  J:ACTIONS: mymoniker!second
template_arguments: {}
fragments: {}
=== two different actions
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker!second
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A-second: DoThat
  J:A:F-id-second: 42
  J:A:F-something-second: bla
  J:ACTIONS: mymoniker!second
template_arguments: {}
fragments: {}
=== ignore arguments without actions
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker!second
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A:F-id-second: 42
  J:A:F-something-second: bla
  J:ACTIONS: mymoniker!second
template_arguments: {}
fragments: {}
=== one active, one inactive action
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: second
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 0
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A-second: DoThat
  J:A:F-id-second: 42
  J:A:F-something-second: bla
  J:ACTIONS: second
template_arguments: {}
fragments: {}
=== two actions, no J:ACTIONS
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: bla
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A-second: DoThat
  J:A:F-id-second: 42
  J:A:F-something-second: bla
template_arguments: {}
fragments: {}
=== ignore totally random stuff
--- form
J:A: bloopybloopy
J:A-mymoniker: DoSomething
J:A:E-id-mymoniker: 5423
J:A:F-id-mymoniker: 23
asdfk-asdfkjasdlf:J:A:F-asdkfjllsadf: bla
J:A:F-something-mymoniker: else
foo: bar
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: bla
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
arguments:
  J:A: bloopybloopy
  J:A-mymoniker: DoSomething
  J:A:E-id-mymoniker: 5423
  J:A:F-id-mymoniker: 23
  asdfk-asdfkjasdlf:J:A:F-asdkfjllsadf: bla
  J:A:F-something-mymoniker: else
  foo: bar
  J:A-second: DoThat
  J:A:F-id-second: 42
  J:A:F-something-second: bla
template_arguments: {}
fragments: {}
=== order doesn't matter
--- form
J:A:F-id-mymoniker: 23
J:A:F-something-second: bla
J:A:F-id-second: 42
J:A-second: DoThat
J:A:F-something-mymoniker: else
J:A-mymoniker: DoSomething
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
arguments:
  J:A:F-id-mymoniker: 23
  J:A:F-something-second: bla
  J:A:F-id-second: 42
  J:A-second: DoThat
  J:A:F-something-mymoniker: else
  J:A-mymoniker: DoSomething
template_arguments: {}
fragments: {}
=== fallbacks being ignored
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F:F-id-mymoniker: 96
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F:F-id-mymoniker: 96
  J:A:F-something-mymoniker: else
  J:ACTIONS: mymoniker
template_arguments: {}
fragments: {}
=== fallbacks being ignored (other order)
--- form
J:A-mymoniker: DoSomething
J:A:F:F-id-mymoniker: 96
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
arguments:
  J:A-mymoniker: DoSomething
  J:A:F:F-id-mymoniker: 96
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:ACTIONS: mymoniker
template_arguments: {}
fragments: {}
=== fallbacks being used
--- form
J:A-mymoniker: DoSomething
J:A:F:F-id-mymoniker: 96
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 96
        something: else
arguments:
  J:A-mymoniker: DoSomething
  J:A:F:F-id-mymoniker: 96
  J:A:F-something-mymoniker: else
  J:ACTIONS: mymoniker
template_arguments: {}
fragments: {}
=== two different actions, one with fallback, one without
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A:F:F-something-second: bla
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: feepy
J:ACTIONS: mymoniker!second
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: feepy
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A:F:F-something-second: bla
  J:A-second: DoThat
  J:A:F-id-second: 42
  J:A:F-something-second: feepy
  J:ACTIONS: mymoniker!second
template_arguments: {}
fragments: {}
=== just validating
---- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoSomething
J:VALIDATE: 1
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker;second
--- request
uri: http:///
state_variables: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoSomething
    active: 1
    has_run: 0
    arguments:
        id: 42
        something: bla
just_validating: 1
arguments:
  J:A-mymoniker: DoSomething
  J:A:F-id-mymoniker: 23
  J:A:F-something-mymoniker: else
  J:A-second: DoSomething
  J:VALIDATE: 1
  J:A:F-id-second: 42
  J:A:F-something-second: bla
  J:ACTIONS: mymoniker!second
template_arguments: {}
fragments: {}
