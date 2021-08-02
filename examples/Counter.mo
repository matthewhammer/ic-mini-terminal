import Types "../src/Types";
import Render "../src/Render";
import Mono5x5 "../src/glyph/Mono5x5";
import Term "../src/terminal/Terminal";
import Nat "mo:base/Nat";

actor {

  type Dim = Term.Dim;
  type Elm = Term.Elm;
  type EventInfo = Term.EventInfo;

  module Style {
    public func horzTextFlow(zm : Nat) : Render.FlowAtts = {
      dir=#right;
      interPad=zm;
      intraPad=zm;
    };
    public func txtAtts(zm : Nat) : Render.BitMapTextAtts = {
      zoom = zm;
      fgFill = #closed((100, 100, 100));
      bgFill = #none;
      flow = horzTextFlow(zm);
    };
  };

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

  func _subTypeCheck(c : Counter) : Term.Core {
    c
  };

  var term = Term.Basic(Counter(0));

  public query func view(dim : Dim, events : [EventInfo]) : async Term.ViewResult {
    term.view(dim, events)
  };

  public func update(events : [EventInfo], gfxReq : Term.GfxReq) : async Term.UpdateResult {
    term.update(events, gfxReq)
  };

}
