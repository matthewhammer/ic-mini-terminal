# IC Game Terminal

Simple, direct keyboard input (⌨) and graphical output (📺) for programs on the [Internet Computer](https://dfinity.org/).

For creating interactive graphics and games.


## Building and testing

### Prerequisites

 * `dfx` via the [DFINITY SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html)
 * [`vessel` package manager](https://github.com/kritzcreek/vessel) for Motoko.

### Run the test canister within the replica

Use `dfx` and `vessel` to build and run the test canister.

First, in one terminal:

```
dfx start
```

Then, in another terminal:

```
dfx canister create --all
dfx build
dfx canister install --all
```

Last, choose a canister to act as the graphics server and connect via `icgt`:


### Run the tool

Use `cargo` to build and run the `icgt` tool.

The `connect` subcommand sends messages to a _graphics server canister_
hosted on the replica:

```
cargo run -- connect 127.0.0.1:8000 `dfx canister id mazeGame`
```

Notice how `dfx canister id` gets the canister's identity for the terminal connection from the canister's name `mazeGame`.

The test canisters installed in the steps just above each
expose this "graphics server" interface.


### Interact with graphics server

The graphics server is a canister running on the replica.

This (remote) canister depends on this (local) terminal for displaying a graphical output window to a human user, and for accepting keyboard input from this user.

#### Graphical output format

Each call to the graphics server yields a response that contains graphics to render:

```
  public type Res = Result.Result<Render.Out, Render.Out>;
```

The `Render.Out` type represents simple graphics sent from the graphics server to the terminal, currently defined by [`motoko-redraw`](https://github.com/matthewhammer/motoko-redraw).

There are three game terminal events that precipitate a server call:

#### 📺 Window resizing

Change the graphical window size of the terminal, and redraw the output:

```
windowSizeChange : (dim:Render.Dim) -> async Res
```

#### 🕒 Time (external clock) advancing

Advance time of the graphics server, and redraw:

```
tick : (duration:Nat) -> async Res
```

#### ⌨ Keyboard input events

Accept keyboard input events, and redraw:

There are two messages sent from the terminal to the server for keyboard input:

```
  updateKeyDown : (keys : Keys) -> async Res;
  queryKeyDown : query (keys : Keys) -> async Res;
```

Each provides a sequences of keyboard key presses:

```
  type Key = {
    key : Text;
    alt : Bool;
    ctrl : Bool;
    meta: Bool;
    shift: Bool
  };
  type Keys = [Key];
```

#### Event semantics

The `tick` and `windowSizeChange` messages indicate time and window geometry events, respectively.

Note: The `tick` command is unused for games without the need of a clock. It's currently NYI.

The `updateKeyDown` and `queryKeyDown` messages convey a keyboard
buffer, of type `Keys`.

These two message types each use and influence the local keyboard buffer
state, in related and complementary ways.

 - sent as an update (and drained), _or_
 - sent as a query, to be appended and re-sent again later.

Often, there is a large (~10x) difference in response time, permitting the local graphics to repaint (much) faster in response to this updated keyboard buffer.

To do so, the graphics server responds to the query messages by _hypothetically projecting its state forward_ but without committing to it.
The response to the local terminal looks _as if_ all of the keyboard events in the buffer were really processed.
In actuality, this buffer is saved locally and resent when it grows or must be committed.

Excessive (or exclusive) use of `queryKeyDown` has limitations, however:

 - It doesn't _acually_ update the graphical server state; rahter, it just queries it, and asks for a forward projection of its state.
 - Any concurrent, cooperating users cannot observe these forward projection effects.
 - Each `queryKeyDown` without an `updateKeyDown` must re-communicate buffered keyboard events and must re-process their effects in this forward projection.

The most responsive local behavior should mix these complementary message kinds.

However, the details of this mixing are still
unclear, so the current implementation permits the user to explicitly
control the buffer's expansion and draining via a meta keyboard key (SHIFT).

#### Keyboard buffering semantics

The SHIFT key permits the expert user to control how the keyboard
buffer is drained and sent to the graphics server:


* When the interactive user holds down SHIFT key, she **queries** the
graphics server via `queryKeyDown` with a key buffer that expands with each new key press,
and the server re-runs the graphics processing for each key of
the buffer each time, and redraws.

* Since it uses only a _query message_ to the graphics server (not an _update_
message), this processing is repeated for each key (a quadratic
expansion, in the limit), but it does not require consensus, so while
redundant, the overall response time is about *ten times faster* than doing a real update to the server state.

* When the interactive user releases the SHIFT key, and then presses another key --- the terminal
resends the buffer plus the new key, and does a real update via `updateKeyDown`.  Now the state change is saved.


# Inspired by

 * [IC-Logo](https://github.com/chenyan2002/ic-logo): A toy [Logo](https://en.wikipedia.org/wiki/Logo_(programming_language))-like language for the Internet Computer.
 * Simple interactive graphics demos and games of [Elm lang](https://elm-lang.org/).
 * Fantasy console [PICO-8](https://www.lexaloffle.com/pico-8.php) ([PICO-8 Manual](https://www.lexaloffle.com/pico8_manual.txt)).
 * [Languages of Play: Towards semantic foundations for game interfaces](https://arxiv.org/abs/1703.05410) ([Chris Martens](https://sites.google.com/ncsu.edu/cmartens) and Matthew Hammer, March 2017).
 * [Lock-Step Simulation Is Child’s Play (Experience Report)](https://www.joachim-breitner.de/publications/CodeWorld-ICFP17.pdf) ([Joachim Breitner](https://www.joachim-breitner.de/blog) and [Chris Smith](https://github.com/cdsmith))
