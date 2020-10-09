# IC Game Terminal

Simple, direct keyboard input (⌨) and graphical output (📺) for programs on the [Internet Computer](https://dfinity.org/).

For creating interactive graphics and games.


## Building and testing

### Prerequisites

 * `dfx` via the [DFINITY SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html)
 * [`vessel` package manager](https://github.com/kritzcreek/vessel) for Motoko.

### Quick starts

 * [Text editor](#text-editor)
 * [Maze game](#maze-game)

#### Text editor

```
./textEdit.sh
```

The script invokes the following commands (eliding some details):

```
dfx -vv start --clean --background
dfx canister create textEdit

dfx build textEdit
dfx canister install textEdit

cargo run --release -- connect 127.0.0.1:8000 `dfx canister id textEdit`
```

The first two commands start the replica and create an identifier for the canister.

The next two commands build the canister from Motoko source code and install it into the running replica's state.

The final command builds and attaches the (local) terminal process to the (remote) canister running in the replica.


#### Maze game





# Inspired by

 * [IC-Logo](https://github.com/chenyan2002/ic-logo): A toy [Logo](https://en.wikipedia.org/wiki/Logo_(programming_language))-like language for the Internet Computer.
 * Simple interactive graphics demos and games of [Elm lang](https://elm-lang.org/).
 * Fantasy console [PICO-8](https://www.lexaloffle.com/pico-8.php) ([PICO-8 Manual](https://www.lexaloffle.com/pico8_manual.txt)).
 * [Languages of Play: Towards semantic foundations for game interfaces](https://arxiv.org/abs/1703.05410) ([Chris Martens](https://sites.google.com/ncsu.edu/cmartens) and Matthew Hammer, March 2017).
 * [Lock-Step Simulation Is Child’s Play (Experience Report)](https://www.joachim-breitner.de/publications/CodeWorld-ICFP17.pdf) ([Joachim Breitner](https://www.joachim-breitner.de/blog) and [Chris Smith](https://github.com/cdsmith))
