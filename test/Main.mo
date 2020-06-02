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

  var state : State = {
    var count = 0;
  };

  var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  public func windowSizeChange(dim:Render.Dim) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    drawWorld(state.count)
  };

  func drawWorld(n : Nat) : Result.Result<Render.Out, Render.Out> {
    let r = Render.Render();
    r.fill(#closed((0, 0, 0)));
    r.begin(#flow{dir=#down;interPad=1;intraPad=1;});
    for (i in I.range(0, n)) {
      r.begin(#flow{dir=#down;interPad=1;intraPad=1;});
      r.rect({pos={x=0;y=0};dim={width=10;height=10}}, #closed((200, 100, 50)));
      r.elm(fibTree(windowDim.width - 10, i, true));
      r.rect({pos={x=0;y=0};dim={width=10;height=10}}, #closed((50, 100, 200)));
      r.end()
    };
    r.end();
    #ok(#draw(r.getElm()))
  };

  public func updateKeyDown( kes : [KeyInfo] ) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "updateKeyDown";
    Debug.print (debug_show kes);
    state.count += kes.len(); // update the mutable state
    drawWorld(state.count)
  };

  public query func queryKeyDown( kes : [KeyInfo] ) : async Result.Result<Render.Out, Render.Out> {
    Debug.print "queryKeyDown";
    Debug.print (debug_show kes);
    drawWorld(state.count + kes.len()) // draw the world as if we updated mutable state, but do not
  };

  public func tick() : async Result.Result<Render.Out, Render.Out> {
    Debug.print "tick";
    state.count += 1;
    drawWorld(state.count)
  };



  func fibTree(treeWidth:Nat, depth:Nat, bit:Bool) : Render.Elm {
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
                    if (bit) {
                      #down
                    } else {
                      #right
                    };
                    interPad=0;intraPad=0;
              });
      r.fill(#open((230, 0, 230), 1));
      let w = (treeWidth / 2);
      r.elm(fibTree(w, depth - 2, bit));
      r.elm(fibTree(w, depth - 1, not bit));
      r.end();
    };
    r.end();
    r.getElm()
  };

}
