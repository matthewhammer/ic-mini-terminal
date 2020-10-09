# IC Game Terminal

Simple, direct keyboard input (⌨) and graphical output (📺) for programs on the [Internet Computer](https://dfinity.org/).

For creating interactive graphics and games.


## Building and testing

### Prerequisites

 * `dfx` via the [DFINITY SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html)
 * [`vessel` package manager](https://github.com/kritzcreek/vessel) for Motoko.

### Quick starts

See examples:

 * [Text editor](#text-editor)
 * [Maze game](#maze-game)

#### Text editor

Run the text edtior demo in a local replica (using `dfx`):

```
./scripts/textEdit.sh
```

The script invokes several `dfx` commands, and builds the terminal binary.

Eliding some details, it works in three stages:

1. The first two commands start the replica and create an identifier for the canister:

  ```
  dfx -vv start --clean --background
  dfx canister create textEdit
  ```

2. The next two commands build the canister from Motoko source code and install it into the running replica's state:

  ```
  dfx build textEdit
  dfx canister install textEdit
  ```

3. The final command builds and attaches the (local) terminal process to the (remote) canister running in the replica:

  ```
  cargo run --release -- connect 127.0.0.1:8000 `dfx canister id textEdit`
  ```


##### Developer notes

- By repeating (only) the `dfx build` and `dfx canister install` steps,
  one can rebuild and re-install the canister within the same replica process.

- By deleting `.vessel` when some (external) package of Motoko source changes,
  one triggers a new clone of the (updated) code, and afterward, `dfx build` will incorporate this updated code.

- The local terminal should keep working with the new (`reinstall`ed) canister.

- Re-running the `cargo run` step is needed if one modifies the terminal source code (in Rust).




#### Maze game

Invoke the maze game as follows:

```
./scripts/mazeGame.sh
```

This script follows the same `dfx`-based scripting template as [`textEdit`](#text-editor), where more details are explained.


# Inspired by

 * [IC-Logo](https://github.com/chenyan2002/ic-logo): A toy [Logo](https://en.wikipedia.org/wiki/Logo_(programming_language))-like language for the Internet Computer.
 * Simple interactive graphics demos and games of [Elm lang](https://elm-lang.org/).
 * Fantasy console [PICO-8](https://www.lexaloffle.com/pico-8.php) ([PICO-8 Manual](https://www.lexaloffle.com/pico8_manual.txt)).
 * [Languages of Play: Towards semantic foundations for game interfaces](https://arxiv.org/abs/1703.05410) ([Chris Martens](https://sites.google.com/ncsu.edu/cmartens) and Matthew Hammer, March 2017).
 * [Lock-Step Simulation Is Child’s Play (Experience Report)](https://www.joachim-breitner.de/publications/CodeWorld-ICFP17.pdf) ([Joachim Breitner](https://www.joachim-breitner.de/blog) and [Chris Smith](https://github.com/cdsmith))
