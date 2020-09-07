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
    var count = 0 : Nat;
  };

  flexible var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  func fib(ctx:Render.Dim, c:Nat, isQueryView:Bool) : Render.Elm {
    let (zero, one, other) = {
      if isQueryView {
        (#open((255, 200, 255), 1),
         #closed((255, 200, 255)),
         #open((255 - ((c * 6) % 255), 255, (255 + c * 11) % 255), 1)
        )
      } else {
        (#open((255, 255, 255), 1),
         #closed((255, 255, 255)),
         #open((255 - ((c * 5) % 255), 255, (255 + c * 10) % 255), 1)
        )
      }
    };
    switch c {
      case 0 { #rect({pos={x=0;y=0};dim=ctx}, zero) };
      case 1 { #rect({pos={x=0;y=0};dim=ctx}, one) };
      case _ {
             if (ctx.width <= 3) {
               #rect({pos={x=0;y=0};dim={width=ctx.width;height=ctx.height * 5}}, other)
             }
             else {
               let ctx2 = {
                 width=(ctx.width - 2) / 2;
                 height=(ctx.height * 8) / 13;
               };
               let r = Render.Render();
               r.begin(#flow{dir=#right;interPad=0;intraPad=0});
               r.fill(other);
               r.elm(fib(ctx2, c - 1, isQueryView));
               r.elm(fib(ctx2, c - 2, isQueryView));
               r.end();
               r.getElm()                 
             }
           }
    }
  };

  func render(c:Nat, isQueryView:Bool) : Render.Result {
    Debug.print "fib";
    Debug.print (debug_show c);
    #ok(#draw(fib(windowDim, c, isQueryView)))
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

  public func windowSizeChange(wdim:Render.Dim) : async Render.Result {
    Debug.print "windowSizeChange";
    Debug.print (debug_show wdim);
    windowDim := wdim;
    render(state.count, false)
  };

  public func updateKeyDown( keys : [KeyInfo] ) : async Render.Result {
    Debug.print "updateKeyDown";
    Debug.print (debug_show keys);
    state.count := adjustCount(keys);
    render(state.count, false)
  };

  public query func queryKeyDown( keys : [KeyInfo] ) : async Render.Result {
    Debug.print "queryKeyDown";
    Debug.print (debug_show keys);
    let temp = adjustCount(keys);
    render(temp, true)
  };

}
