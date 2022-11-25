COMP2310 Assignment 2: Passing the Message
==========================================

So you've decided to attempt (or are considering attempting) Assignment 2 in a
programming language you've (presumably) never even seen, much less used.

Firstly, let me commend you on your choice of language. Erlang is a
**functional** language, designed for building **distributed**,
**fault-tolerant** systems. It was developed at telecommunications company
Ericsson in the 1980s for their extremely large, expensive routers, which are
designed to run for years without rebooting or dropping a single communication.
It's been open source since 1998, and is still popular today, mainly for
implementing the backend servers for chat systems (some of Discord's servers
run Erlang) and MMO and other multiplayer game servers, where all of these
properties are extremely desirable.

**functional**: remember Haskell from COMP1100/COMP1130? Unlike Haskell,
Erlang isn't _lazy_, so don't expect to generate infinite lists and other such
shenanigans; neither is it _pure_, so your functions can have whatever side
effects you desire. However, the rest of the goodies are still there - higher
order functions (like lists:map(F, X) and lists:zipWith(F, X, Y)) and recursive
functions too (which this framework makes heavy use of). By itself, Erlang is
dynamically typed - so your lists can contain whatever you like - but there's
an optional static type checker called the Dialyzer that effectively turns
Erlang into a statically typed language. Lines starting with `-spec` are type
signatures - see below for how to run the type checker.

**distributed**: while you won't be dealing with it for this assignment, Erlang
will happily pass messages between not just multiple processes, but processes
running on totally different systems! Basically all communication between
processes is via message passing, as a functional language means basically no
shared resources. Erlang's native message passing is asynchronous (which makes
this assignment far too easy), so your router is using something called
`gen_server`, which is a standard way to implement _synchronous_ communication
between tasks.

**fault-tolerant:** again, this won't really come up for this assignment, but
Erlang has very sophisticated ways to handle and gracefully recover from errors
in systems with dozens or hundreds of interdependent processes.

I could talk about this language forever - we haven't even mentioned live code
upgrades or any of the other truly awesome features - but you're probably
overwhelmed enough already.

Getting Started
---------------

First, you'll need to install Erlang, plus the rebar3 build tool. If you're on
Linux, your package manager probably has these - they might be out of date, but
anything newer than Erlang/OTP 18.0 will probably work. (The latest version as
of this writing is 23.1.)

Building
--------

To build:

    $ rebar3 escriptize

To run:

    $ _build/default/bin/test_routers

This takes most of the same arguments as the Ada framework - to switch to a
different topology, use (e.g.) `-t Hypercube`. You can read all the parameters
available in `test_routers.erl`.

To run the static type checker (highly recommended):

    $ rebar3 dialyzer

The Assignment
--------------

Most of your work will be done in `router.erl`. The `handle_call` function
handles all the various framework messages already - all you need to deal with
is getting messages from A to B. You can add more variables to the internal
state on line 10 (make sure you initialise them somewhere!), handle routing
test messages on line 45, and deal with message types of your own on line 41.

Where To Get Help
-----------------

The Erlang documentation is high-quality, and comes with built-in search:
<https://erlang.org/doc/search/>. This will become your go-to reference, but
you'll want to pick up the basics of the language first.

The Erlang team themselves have a [Getting Started with Erlang][2] guide that's
pretty good, and very brief.

[Learn You Some Erlang For Great Good][3], just like its Haskell sibling, is a
well-thought-out and readable (but long) introduction to the language.

If you prefer to learn by example: [Learn X in Y minutes, where X=erlang][4] is
a good whirlwind tour, while [Rosetta Code][5] contains more detailed examples.

And remember: Google is your friend.

[2]: https://erlang.org/doc/getting_started/users_guide.html
[3]: https://learnyousomeerlang.com/content
[4]: https://learnxinyminutes.com/docs/erlang/
[5]: https://rosettacode.org
