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
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
=== two actions
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoSomething
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker;second
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoSomething
    active: 1
    arguments:
        id: 42
        something: bla
=== two different actions
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker;second
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    arguments:
        id: 42
        something: bla
=== ignore arguments without actions
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker;second
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
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
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 0
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    arguments:
        id: 42
        something: bla
=== two actions, no J:ACTIONS
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: bla
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    arguments:
        id: 42
        something: bla
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
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    arguments:
        id: 42
        something: bla
=== order doesn't matter
--- form
J:A:F-id-mymoniker: 23
J:A:F-something-second: bla
J:A:F-id-second: 42
J:A-second: DoThat
J:A:F-something-mymoniker: else
J:A-mymoniker: DoSomething
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    arguments:
        id: 42
        something: bla
=== fallbacks being ignored
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F:F-id-mymoniker: 96
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
=== fallbacks being ignored (other order)
--- form
J:A-mymoniker: DoSomething
J:A:F:F-id-mymoniker: 96
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
=== fallbacks being used
--- form
J:A-mymoniker: DoSomething
J:A:F:F-id-mymoniker: 96
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 96
        something: else
=== two different actions, one with fallback, one without
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A:F:F-something-second: bla
J:A-second: DoThat
J:A:F-id-second: 42
J:A:F-something-second: feepy
J:ACTIONS: mymoniker;second
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoThat
    active: 1
    arguments:
        id: 42
        something: feepy
=== double fallbacks being ignored (with single fallback)
--- form
J:A-mymoniker: DoSomething
J:A:F:F:F-id-mymoniker: 789
J:A:F:F-id-mymoniker: 456
J:A:F-id-mymoniker: 123
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 123
        something: else
=== double fallbacks being ignored (without single fallback)
--- form
J:A-mymoniker: DoSomething
J:A:F:F:F-id-mymoniker: 789
J:A:F-id-mymoniker: 123
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 123
        something: else
=== double fallbacks being ignored (single fallback used)
--- form
J:A-mymoniker: DoSomething
J:A:F:F:F-id-mymoniker: 789
J:A:F:F-id-mymoniker: 456
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 456
        something: else
=== double fallbacks being used
--- form
J:A-mymoniker: DoSomething
J:A:F:F:F-id-mymoniker: 789
J:A:F-something-mymoniker: else
J:ACTIONS: mymoniker
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 789
        something: else
=== just validating
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:A:F-something-mymoniker: else
J:A-second: DoSomething
J:VALIDATE: 1
J:A:F-id-second: 42
J:A:F-something-second: bla
J:ACTIONS: mymoniker;second
--- request
helpers: {}
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
  second:
    moniker: second
    class: DoSomething
    active: 1
    arguments:
        id: 42
        something: bla
just_validating: 1
=== one action, one helper (using same moniker just to confuse you)
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:H-mymoniker: Jifty::View::Helper::This
J:A:F-something-mymoniker: else
J:H:S-bla-mymoniker: foo
--- request
helpers:
  mymoniker:
    moniker: mymoniker
    class: Jifty::View::Helper::This
    states:
      bla: foo
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
=== one action, one helper (different monikers)
--- form
J:A-mymoniker: DoSomething
J:A:F-id-mymoniker: 23
J:H-yourmoniker: Jifty::View::Helper::This
J:A:F-something-mymoniker: else
J:H:S-bla-yourmoniker: foo
--- request
helpers:
  yourmoniker:
    moniker: yourmoniker
    class: Jifty::View::Helper::This
    states:
      bla: foo
actions:
  mymoniker:
    moniker: mymoniker
    class: DoSomething
    active: 1
    arguments:
        id: 23
        something: else
=== just a helper
--- form
J:H-yourmoniker: Jifty::View::Helper::This
J:H:S-bla-yourmoniker: foo
--- request
helpers:
  yourmoniker:
    moniker: yourmoniker
    class: Jifty::View::Helper::This
    states:
      bla: foo
actions: {}
=== two helpers
--- form
J:H-yourmoniker: Jifty::View::Helper::This
J:H-hismoniker: Jifty::View::Helper::That
J:H:S-bla-yourmoniker: foo
J:H:S-bap-yourmoniker: baz
J:H:S-bla-hismoniker: feep
J:H:S-bot-hismoniker: asdf
--- request
helpers:
  yourmoniker:
    moniker: yourmoniker
    class: Jifty::View::Helper::This
    states:
      bla: foo
      bap: baz
  hismoniker:
    moniker: hismoniker
    class: Jifty::View::Helper::That
    states:
      bla: feep
      bot: asdf
actions: {}
