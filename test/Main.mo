import Result "mo:base/result";
import Render "mo:redraw/render";
import Array "mo:base/array";
import I "mo:base/iter";
import Debug "mo:base/Debug";

actor {

  var n = 1;

  var windowDim : Render.Dim = {
    width = 0;
    height = 0;
  };

  public func windowSizeChange(dim:Render.Dim) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    drawWorld()
  };

  func fibTree(depth:Nat) : Render.Elm {
    let r = Render.Render();
    if (depth <= 2) {
      r.rect({pos={x=0; y=0}; dim={width=10; height=10}}, #closed(255, 0, 255))
    } else {
      r.begin(#flow{dir=#right;interPad=5;intraPad=5;});
      r.fill(#open((230, 0, 230), 1));
      r.elm(fibTree(depth - 2));
      r.elm(fibTree(depth - 1));
      r.end();
    };
    r.getElm()
  };

  func drawWorld() : Result.Result<Render.Out, Render.Out> {
    let r = Render.Render();
    r.begin(#flow{dir=#right;interPad=5;intraPad=5;});
    r.elm(fibTree(n));
    r.end();
    #ok(#draw(r.getElm()))
  };

  public func tick() : async Result.Result<Render.Out, Render.Out> {
    Debug.print "tick";
    n := n + 1;
    drawWorld()
  };
}
