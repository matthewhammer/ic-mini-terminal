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

  func drawWorld() : Result.Result<Render.Out, Render.Out> {
    func getRect(n:Nat) : Render.Rect = {
      let fluff = if(n < 10){11 - n} else { 5 };
      {
        pos={x=0; y=0} : Render.Pos; // position ignored, we are using a flow layout
        dim={width=20 - fluff;
             height=fluff}
      }
    };
    
    func getFill(n:Nat) : Render.Fill = 
      #closed((254 * (n % 3) + 1,
               200 / ((n % 3) + 1),
               if (n < 10) { 255 - (n * 5) } else { 200 }));
    
    let r = Render.Render();
    r.begin(#flow{dir=#right;interPad=5;intraPad=5;});
    if (n > 0) {
      for (i in I.range(0, n - 1)) {
        r.rect(getRect i, getFill i)
      };
    } else {
      r.text("0", textAtts())
    };
    r.end();
    #ok(#draw(r.getElm()))
  };

  public func tick() : async Result.Result<Render.Out, Render.Out> {
    Debug.print "tick";
    n := n + 1;
    drawWorld()
  };

  func textAtts() : Render.TextAtts = {
    zoom=1;
    fgFill=#none;
    bgFill=#none;
    glyphDim={width=5;height=5};
    glyphFlow={
      dir=#right;
      interPad=2;
      intraPad=1;
    }
  };
}
