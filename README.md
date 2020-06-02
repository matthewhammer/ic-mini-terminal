# IC Game Terminal

Simple keyboard input and graphical output for the Internet Computer.

For playing games, viewing graphics and more.


## Building and testing

### Prerequisites

 * `dfx` via the [DFINITY SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html)
 * [`vessel` package manager](https://github.com/kritzcreek/vessel) for Motoko.

### Run the test canister within the replica

Use `dfx` and `vessel` to build and run the test canister.

 * First, in one terminal:
```
dfx start
```

 * Then, in another terminal:
```
dfx build
dfx canister install --all
```

 * Last, use the canister ID printed back on the terminal to connect `icgt`


### Run the tool

Use `cargo` to build and run the `icgt` tool.

The `connect` subcommand sends messages to a _game server canister_
hosted on the replica:

```
cargo run -- connect 127.0.0.1:8000 ic:06AB8F2EB9EB6699D6
```

The test canisters installed in the steps just above each
expose this "game server" interface.


### Interact with game server


#### Keyboard input

There are four messages sent from the terminal to the server:

```
  tick : () -> async Res;
  windowSizeChange : (dim : Render.Dim) -> async Res;
  updateKeyDown : (keys : KeyInfos) -> async Res;
  queryKeyDown : query (keys : KeyInfos) -> async Res;
```

Several game server messages provide sequences of keyboard key presses:

```
  type KeyInfo = {
    key : Text;
    alt : Bool;
    ctrl : Bool;
    meta: Bool;
    shift: Bool
  };
  type KeyInfos = [KeyInfo];
```

#### Graphics output

Each call to the game server yields a response that contains graphics to render:

```
  public type Res = Result.Result<Render.Out, Render.Out>;
```

#### Event semantics and timing

The `tick` and `windowSizeChange` messages indicate time and window geometry events, respectively.

Note: The `tick` command is unused for games without the need of a clock. It's currently NYI.

The `updateKeyDown` and `queryKeyDown` messages are related, and the SHIFT key controls when they are each used:

* When the interactive user holds down SHIFT key, she **queries** the
game server via `queryKeyDown` with a key buffer that expands with each new key press,
and the test server re-runs the graphics processing for each key of
the buffer each time, and redraws.

* Since it uses only a _query message_ to the server (not an _update_
message), this processing is repeated for each key (a quadratic
expansion, in the limit), but it does not require consensus, so while
redundant, the overall response time is about *ten times faster* than doing a real update to the server state.

* When the interactive user releases the SHIFT key, and then presses another key --- the terminal
resends the buffer plus the new key, and does a real update via `updateKeyDown`.  Now the state change is saved.
