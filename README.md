# IC Mini Terminal (`ic-mt`)

Minimal keyboard input (⌨) and graphical output (📺) for programs on the [Internet Computer](https://dfinity.org/).

## Technical spec

The `ic-mt` tool talks to any
[Internet Computer service]() that uses its
update-view service protocol, given below in Candid syntax (eliding details):

```
service : {
  update: (vec EventInfo) -> () oneway;
  view: (Dim, vec EventInfo) -> (Graphics) query;
}
```

For details, see the [full Candid spec](https://github.com/matthewhammer/ic-mini-terminal/blob/master/service.did), and those for [Candid](https://github.com/dfinity/candid).

## Building and testing

Requirements:

 * Rust and `cargo`
 * `dfx` via the [DFINITY SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html)

Optionally:

 * [MirrorGarden](https://github.com/matthewhammer/MirrorGarden): A Motoko project that uses this tool.
 * [`vessel` package manager](https://github.com/kritzcreek/vessel) for Motoko.

The mini terminal is a Rust project.

We typically use `dfx` to run the Internet Computer services (e.g., within a local replica)
to run applications for the terminal.

We often write these applications in [Motoko](https://sdk.dfinity.org/docs/language-guide/motoko.html).

## Inspired by

 * [IC-Logo](https://github.com/chenyan2002/ic-logo): A toy [Logo](https://en.wikipedia.org/wiki/Logo_(programming_language))-like language for the Internet Computer.
 * Simple interactive graphics demos and games of [Elm lang](https://elm-lang.org/).
 * Fantasy console [PICO-8](https://www.lexaloffle.com/pico-8.php) ([PICO-8 Manual](https://www.lexaloffle.com/pico8_manual.txt)).
 * [Languages of Play: Towards semantic foundations for game interfaces](https://arxiv.org/abs/1703.05410) ([Chris Martens](https://sites.google.com/ncsu.edu/cmartens) and Matthew Hammer, March 2017).
 * [Lock-Step Simulation Is Child’s Play (Experience Report)](https://www.joachim-breitner.de/publications/CodeWorld-ICFP17.pdf) ([Joachim Breitner](https://www.joachim-breitner.de/blog) and [Chris Smith](https://github.com/cdsmith))
