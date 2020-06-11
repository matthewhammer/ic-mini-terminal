import Result "mo:base/result";
import Render "mo:redraw/render";
import Array "mo:base/array";
import I "mo:base/iter";
import Debug "mo:base/Debug";
import P "mo:base/Prelude";

actor {

  type KeyInfo = {
    key : Text;
    alt : Bool;
    ctrl : Bool;
    meta: Bool;
    shift: Bool
  };

  type State = {
    var count : Nat
  };

  flexible var state : State = {
    var count = 0;
  };

  flexible var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  public func windowSizeChange(dim:Render.Dim) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    drawWorld(state.count, false)
  };

  func countOfKeys(n : Nat, keys : [KeyInfo]) : Nat {
    var count = n;
    for (key in keys.vals()) {
      switch (key.key) {
        case "ArrowLeft" { if (count > 1) { count -= 1 } };
        case "ArrowRight" { count += 1 };
        case _ { /* do nothing */ };
      }
    };
    count
  };

  func drawWorld(n : Nat, isQueryView : Bool) : Result.Result<Render.Out, Render.Out> {
    Debug.print ("drawWorld" # debug_show (n, isQueryView));
    let r = Render.Render();
    if isQueryView {
      r.fill(#closed((0, 0, 0)));
    } else {
      r.fill(#closed((100, 0, 100)));
    };

    // Vertical stacking of rows
    r.begin(#flow{dir=#down;interPad=1;intraPad=1;});
    for (i in I.range(0, n)) {
      r.begin(#flow{dir=#down;interPad=1;intraPad=0;});
      
      r.rect({pos={x=0;y=0};dim={width=5 * i;height=5 + i}},
             if isQueryView { #open((200, 100, 50), 1) } else { #closed((100, 60, 20)) });

      // Horizontal row of boxes
      r.begin(#flow{dir=#right;interPad=1;intraPad=0;});
      for (j in (I.range(0, n))) {
        let color = switch (j % 6) {
          case 0 (200, 100, 50);
          case 1 (200, 200, 20);
          case 2 (200, 250, 10);
          case 3 (100, 100, 60);
          case 4 (100, 200, 70);
          case _ (100, 250, 80);
        };
        let fill = if (isQueryView) { #closed(color) } else { #open(color, 1) };
        r.rect({pos={x=0;y=0};dim={width=3 + i;height=3 + j}}, fill);
        r.rect({pos={x=0;y=0};dim={width=3 + j;height=3 + i}}, fill);
      };
      r.end();
      
      r.rect({pos={x=0;y=0};dim={width=(8 * i) / 5;height=8}}, #closed((50, 100, 200)));
      r.end()
    };
    r.end();
    #ok(#draw(r.getElm()))
  };

  public func updateKeyDown( keys : [KeyInfo] ) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "updateKeyDown";
    Debug.print (debug_show keys);
    state.count := countOfKeys(state.count, keys); // update the mutable state (the counter)
    drawWorld(state.count, false)
  };

  public query func queryKeyDown( keys : [KeyInfo] ) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "queryKeyDown";
    Debug.print (debug_show keys);
    let temp = countOfKeys(state.count, keys);
    drawWorld(temp, true) // draw the world as if we updated mutable state, but do not save.
  };

  public func tick() : async Result.Result<Render.Out, Render.Out> {
    Debug.print "tick";
    state.count += 1;
    drawWorld(state.count, false)
  };


}
