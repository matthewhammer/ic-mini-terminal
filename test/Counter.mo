import Result "mo:base/result";
import Array "mo:base/array";
import I "mo:base/iter";
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

  var state = {
    var count = 0 : Nat;
  };

  var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  func drawRect(c:Nat, isQueryView:Bool) : Render.Result {
    // adjust color based on isQueryView
    let fill = if isQueryView {
      #closed((200, 50, 150))
    } else {
      #closed((255, 200, 180))
    };
    #ok(
      #draw(
        #rect(
          {pos={x=(c * 5 + 5) % windowDim.width; 
                y=(c * 3 + 5) % windowDim.height};
           dim={width=10;height=10}},
          fill)))
  };

  func adjustCount(keys:[KeyInfo]) : Nat {
    var count = state.count;
    for (key in keys.vals()) {
      switch (key.key) {
        case "ArrowLeft" { if (count > 1) { count -= 1 } };
        case "ArrowRight" { count += 1 };
        case _ { /* do nothing */ };
      }
    };
    count
  };

  public func windowSizeChange(dim:Render.Dim) : async Render.Result {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    drawRect(state.count, false)
 };

  public func updateKeyDown( keys : [KeyInfo] ) : async Render.Result {
    Debug.print "updateKeyDown";
    Debug.print (debug_show keys);
    state.count := adjustCount(keys);
    drawRect(state.count, false)
  };

  public query func queryKeyDown( keys : [KeyInfo] ) : async Render.Result {
    Debug.print "queryKeyDown";
    Debug.print (debug_show keys);
    let temp = adjustCount(keys);
    drawRect(temp, true)
  };


}
