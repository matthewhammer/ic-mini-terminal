import Result "mo:base/result";
import Render "mo:redraw/render";
import Array "mo:base/array";
import I "mo:base/iter";
import Debug "mo:base/Debug";
import P "mo:base/Prelude";

actor {

  var n = 1;

  var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  public func windowSizeChange(dim:Render.Dim) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    drawWorld()
  };

  func fibTree(treeWidth:Nat, depth:Nat) : Render.Elm {
    let r = Render.Render();
    r.begin(#none);
    if (depth <= 2) {
      switch depth {
        case 0 r.rect({pos={x=0; y=0}; dim={width=treeWidth; height=1}}, #closed(255, 0, 255));
        case 1 r.rect({pos={x=0; y=0}; dim={width=treeWidth; height=2}}, #closed(255, 100, 255));
        case 2 r.rect({pos={x=0; y=0}; dim={width=treeWidth; height=3}}, #closed(255, 255, 255));
        case _ P.unreachable();
      }
    } else if (treeWidth < 3) {
      r.rect({pos={x=0; y=0}; dim={width=treeWidth; height=4}}, #closed(100, 255, 100))
    } else {
      r.begin(#flow{dir=
                    if (depth % 2 == 0) {
                      #down
                    } else {
                      #right
                    };
                    interPad=0;intraPad=0;
              });
      r.fill(#open((230, 0, 230), 1));
      let w = treeWidth / 2;
      r.elm(fibTree(w, depth - 2));
      r.elm(fibTree(w, depth - 1));
      r.end();
    };
    r.end();
    r.getElm()
  };

  func drawWorld() : Result.Result<Render.Out, Render.Out> {
    let r = Render.Render();
    r.fill(#closed((0, 0, 0)));
    r.begin(#flow{dir=#right;interPad=1;intraPad=1;});
    for (_ in I.range(0, n)) {
      r.elm(fibTree(windowDim.width / 13, 13));
    };
    r.end();
    #ok(#draw(r.getElm()))
  };

  public func tick() : async Result.Result<Render.Out, Render.Out> {
    Debug.print "tick";
    n := n + 1;
    drawWorld()
  };
}
