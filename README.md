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

The `connect` subcommand sends `tick` update messages to a canister
hosted on the replica:

```
cargo run -- connect 127.0.0.1:8000 ic:06AB8F2EB9EB6699D6
```


