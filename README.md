# IC Mini Terminal (`ic-mt`)

Minimal keyboard input (⌨) and graphical output (📺) for programs on the [Internet Computer](https://dfinity.org/).

## Example

The Motoko package `icmt` (in this repo, under `src`) provides a simple framework for building services that interact with an `icmt` instance.

Below, we show an interactive `Counter` example.

```motoko
class Counter(initCount : Nat) {
  public var count = initCount;

  public func clone () : Counter {
    Counter(count)
  };

  public func draw (d: Dim) : Types.Graphics.Elm {
    let r = Render.Render();
    let atts = Style.txtAtts(d.width / 256 + 1);
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, atts);
    let tr = Render.TextRender(cr);
    tr.textAtts("count = " # Nat.toText(count), atts);
    r.getElm()
  };

  public func update (e : EventInfo) {
    switch (e.event) {
      case (#keyDown(keys)) {
        for (k in keys.vals()) {
          switch (k.key) {
            case ("=" or "+" or "ArrowUp" or "ArrowRight") {
              count += 1;
            };
            case ("-" or "_" or "ArrowDown" or "ArrowLeft") {
              if (count > 0) { count -= 1 };
            };
            case _ { /* ignore key */ };
          }
        }
      };
      case _ { /* ignore event */ };
    }
  };
};
```

The [full example](https://github.com/matthewhammer/ic-mini-terminal/tree/master/examples/Counter.mo) uses this class to instantiate the [`terminal/Terminal.Basic` class](http://matthewhammer.org/ic-mini-terminal/terminal/Terminal.html#type.Basic), which adapts the simple (single-event) `draw`-`update` protocol shown below to that of the "full" `icmt` service protocol.

## Technical spec

The `ic-mt` tool talks to any
service on the [Internet Computer](https://dfinity.org/) that uses
the mini-terminal update-view service protocol, given below in Candid syntax (eliding message-type details):

```
service : {
  view: (Dim, vec EventInfo) -> (Graphics) query;
  update: (vec EventInfo, GraphicsRequest) -> (vec Graphics);
}
```

See the [full Candid spec](https://github.com/matthewhammer/ic-mini-terminal/blob/master/service.did), and general docs for [Candid](https://github.com/dfinity/candid) for further details.

## Building and testing

Dependencies:

 * Rust and `cargo`
 * `dfx` via the [DFINITY SDK](https://dfinity.org/developers/)
 * [`vessel` package manager](https://github.com/kritzcreek/vessel) for Motoko examples.

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

