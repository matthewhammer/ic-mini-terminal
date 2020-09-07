import Result "mo:base/Result";
import Array "mo:base/Array";
import I "mo:base/Iter";
import Debug "mo:base/Debug";
import P "mo:base/Prelude";
import Render "mo:redraw/Render";

actor {


  type KeyInfo = {
    key : Text;
    alt : Bool;
    ctrl : Bool;
    meta: Bool;
    shift: Bool
  };

  flexible var state = {
    var x = 0 : Nat;
    var y = 0 : Nat;
  };

  flexible var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  func drawRect((_x,_y):(Nat, Nat), isQueryView:Bool) : Render.Result {
    // adjust color based on isQueryView
    let fill = if isQueryView {
      #closed((200, 50, 150))
    } else {
      #closed((255, 200, 180))
    };
    #ok(
      #draw(
        #rect(
          {pos={x=(_x * 5 + 5) % windowDim.width; 
                y=(_y * 3 + 5) % windowDim.height};
           dim={width=10;height=10}},
          fill)))
  };

  func adjustPos(keys:[KeyInfo]) : (Nat, Nat) {
    var x = state.x;
    var y = state.y;
    for (key in keys.vals()) {
      switch (key.key) {
        case "ArrowLeft"  { if (x > 1) { x -= 1 } };
        case "ArrowRight" { x += 1 };
        case "ArrowUp"    { if (y > 1) { y -= 1 } };
        case "ArrowDown"  { y += 1 };
        case _ { /* do nothing */ };
      }
    };
    (x, y)
  };

  public func windowSizeChange(dim:Render.Dim) : async Render.Result {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    drawRect((state.x, state.y), false)
 };

  public func updateKeyDown( keys : [KeyInfo] ) : async Render.Result {
    Debug.print "updateKeyDown";
    Debug.print (debug_show keys);
    let pos = adjustPos(keys);
    state.x := pos.0;
    state.y := pos.1;
    drawRect(pos, false)
  };

  public query func queryKeyDown( keys : [KeyInfo] ) : async Render.Result {
    Debug.print "queryKeyDown";
    Debug.print (debug_show keys);
    let temp = adjustPos(keys);
    drawRect(temp, true)
  };


}
