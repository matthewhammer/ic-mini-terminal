// 2D rendering abstractions
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import P "mo:base/Prelude";
import I "mo:base/Iter";

import Stack "mo:stand/Stack";
import Debug "mo:stand/DebugOff";

import Types "Types";
import GlyphTypes "glyph/Types";
import Mono5x5 "glyph/Mono5x5";

module {

  public type Color = Types.Graphics.Color;
  public type Dim = Types.Dim;
  public type Pos = Types.Pos;
  public type Rect = Types.Rect;
  public type Node = Types.Graphics.Node;
  public type Elm = Types.Graphics.Elm;
  public type Fill = Types.Graphics.Fill;
  public type Elms = Types.Graphics.Elms;
  public type Out = Types.Graphics.Out;
  public type Result = Types.Graphics.Result;

  public type FlowAtts = GlyphTypes.FlowAtts;
  public type Dir2D = GlyphTypes.Dir2D;
  public type BitMapData = GlyphTypes.BitMapData;
  public type BitMapAtts = GlyphTypes.BitMapAtts;
  public type BitMapTextAtts = GlyphTypes.BitMapTextAtts;

  // - - - - - - - - - - - - - -
  public func checkApartRects(rect1:Rect, rect2:Rect) : Bool {
    // case 1: use a vertical division to prove apartness:
    // 1a: (rect1.x + width) < (rect2.x)
    // 1b: (rect2.x + width) < (rect1.x)
    if (rect1.pos.x + rect1.dim.width < rect2.pos.x) { return true };
    if (rect2.pos.x + rect2.dim.width < rect1.pos.x) { return true };
    // case 2: use a horizontal division to prove apartness:
    // 1a: (rect1.y + height) < (rect2.x)
    // 1b: (rect2.y + height) < (rect1.x)
    if (rect1.pos.y + rect1.dim.height < rect2.pos.y) { return true };
    if (rect2.pos.y + rect2.dim.height < rect1.pos.y) { return true };
    // otherwise, they overlap in at least one unit square, perhaps more.
    // we do not construct the intersection here (yet).
    Debug.print( debug_show rect1 );
    Debug.print( debug_show rect2 );
    false
  };

  // because Motoko lacks nice record update syntax
  public func textAttsFg(ta:BitMapTextAtts, fg:Fill) : BitMapTextAtts {
    { zoom = ta.zoom;
      fgFill = fg;
      bgFill = ta.bgFill;
      flow = ta.flow;
    }
  };

  // because Motoko lacks nice record update syntax
  public func textAttsBg(ta:BitMapTextAtts, fg:Fill, bg:Fill) : BitMapTextAtts {
    { zoom = ta.zoom;
      fgFill = fg;
      bgFill = bg;
      flow = ta.flow;
    }
  };

  public func checkElmsApart(elm1:Elm, elm2:Elm) : Bool {
    let rect1 = boundingRectOfElm(elm1);
    let rect2 = boundingRectOfElm(elm2);
    checkApartRects(rect1, rect2)
  };

  public func checkElmValid(elm:Elm) : Bool {
    switch elm {
    case (#node(n)) { checkNodeValid(n) };
    case (#rect(r, f)) { true };
    }
  };

  public func rectEq(rect1:Rect, rect2:Rect) : Bool {
    rect1.pos.x == rect2.pos.x
    and
    rect1.pos.y == rect2.pos.y
    and
    rect1.dim.width == rect2.dim.width
    and
    rect1.dim.height == rect2.dim.height
  };

  public func rectContains(rect1:Rect, rect2:Rect) : Bool {
    rect1.pos.x <= rect2.pos.x
    and
    rect1.pos.y <= rect2.pos.y
    and
    rect1.pos.x + rect1.dim.width >= rect2.pos.x + rect2.dim.width
    and
    rect1.pos.y + rect1.dim.height >= rect2.pos.y + rect2.dim.height
  };

  public func checkNodeValid(node:Node) : Bool {
    Debug.print "checkNodeValid";
    let rect = boundingRectOfElms(node.elms);
    if (rectContains(node.rect, rect)) {
      true
    } else {
      Debug.print( "Internal error: checkNodeValid failed: Node rect does not contain elms' rect:" );
      Debug.print( debug_show node.rect );
      Debug.print( debug_show rect );
      false
    }
  };

  public func checkElmsValid(elms:Elms) : Bool {
    Debug.print "checkElmsValid begin";
    if (elms.size() == 0) {
      return true
    };
    for (i in I.range(0, elms.size() - 1)) {
      Debug.print "checkElmsValid for1-body begin";
      Debug.print (Nat.toText i);
      let elm = elms[i];
      if (not checkElmValid(elm)) {
        return false
      };
      if (i + 1 < ((elms.size() - 1) : Nat)) {
        for (j in I.range(i + 1, elms.size() - 1)) {
          Debug.print "checkElmsValid for2-body begin";
          Debug.print (Nat.toText j);
          let elm2 = elms[j];
          if (not checkElmsApart(elm, elm2)) {
            return false
          };
        };
      };
    };
    Debug.print "checkElmsValid done";
    true
  };

  // - - - - - - - - - - - - - -

  public func rect(x_:Nat, y_:Nat, width_:Nat, height_:Nat) : Rect {
    {
      pos= { x = x_;
             y = y_; };
      dim= { width = width_;
             height = height_ };
    }
  };

  public type FrameType = {
    #none;
    #flow : FlowAtts;
  };

  type Frame = {
    typ: FrameType;
    var fill: Fill;
    elms: Buffer.Buffer<Elm>;
  };

  // composable operations
  public class Render() {

    var frame = {
      var fill=(#none : Fill);
      typ=#none;
      elms=Buffer.Buffer<Elm>(0);
    } : Frame;

    var stack = Stack.Stack<Frame>();

    public func beginFlow(flow:FlowAtts) {
      begin(#flow(flow))
    };

    public func begin(typ_:FrameType) {
      let new_frame : Frame = {
        var fill=(#none : Fill);
        typ=typ_;
        elms=Buffer.Buffer<Elm>(0);
      };
      stack.push(frame);
      frame := new_frame;
    };

    public func fill(f:Fill) {
      frame.fill := f;
    };

    public func nest(r: Render) {
      for (e in r.getElms().vals()) {
        frame.elms.add(e)
      }
    };

    public func elm(e:Elm) {
      frame.elms.add(e)
    };

    public func rect(r:Rect, f:Fill) {
      frame.elms.add(#rect(r, f))
    };

    public func bitmap(bd : BitMapData, ba : BitMapAtts) {
      let cellDim = { width = ba.zoom; height = ba.zoom };
      if (ba.zoom > 0) {
        for (i in I.range(0, bd.dim.width - 1)) {
          for (j in I.range(0, bd.dim.height - 1)) {
            let cellRect = {
              pos = { x = i * ba.zoom;
                      y = j * ba.zoom;
              };
              dim = cellDim;
            };
            let cellFill =
              if (bd.bits[j][i]) ba.fgFill else ba.bgFill;
            rect(cellRect, cellFill);
          }
        };
      };
    };

    public func bitmapText(bdf : Char -> BitMapData, bta : BitMapTextAtts, t: Text) {
      begin(#flow(bta.flow));
      for (c in t.chars()) {
        Debug.print ("bitmapText char: " # (debug_show c));
        begin(#none); // explicit positions below, relative to (0,0):
        bitmap(bdf c, bta);
        end()
      };
      end()
    };

    public func end() {
      Debug.print "end";
      switch (stack.pop()) {
      case null { P.unreachable() };
      case (?frame_1) {
             let frameElm = elmOfFrame(frame);
             if (not (checkElmValid(frameElm))) {
               Debug.print( "ERROR: frame not valid" );
             };
             frame := frame_1;
             frame.elms.add(frameElm)
           };
      }
    };

    public func getElms() : Elms {
      Debug.print "getElms";
      assert(stack.isEmpty());
      let elms = frame.elms.toArray();
      assert(checkElmsValid(elms));
      elms
    };

    public func getElm() : Elm {
      Debug.print "getElm";
      let elms = getElms();
      assert(elms.size() == 1);
      elms[0]
    };

    public func getResult() : Result {
      let elm = getElm();
      #ok(#draw(elm))
    };

  };

  func dimOfElm(elm:Elm) : Dim {
    switch elm {
      case (#node(n)) { n.rect.dim };
      case (#rect(r,_)) r.dim;
    }
  };

  func dim(w:Nat, h:Nat) : Dim {
    { width=w; height=h }
  };

  func dimOfFlow(elms:Elms, flow:FlowAtts) : Dim {
    var width = 0;
    var height = 0;
    let intraPadSum =
      flow.interPad * 2 +
      (if (elms.size() == 0) 0 else
    ((elms.size() - 1) : Nat) * flow.intraPad)
    ;
    switch (flow.dir) {
      case (#left or #right) {
             for (elm in elms.vals()) {
               let dim = dimOfElm(elm);
               width += dim.width;
               if (height < dim.height) {
                 height := dim.height;
               };
             };
             width += intraPadSum;
             height += 2 * flow.interPad;
           };
      case (#up or #down) {
             for (elm in elms.vals()) {
               let dim = dimOfElm(elm);
               height += dim.height;
               if (width < dim.width) {
                 width := dim.width;
               };
             };
             width += 2 * flow.interPad;
             height += intraPadSum;
           };
    };
    dim(width, height)
  };

  func dimOfFrame(frame:Frame) : Dim {
    let dim = switch (frame.typ) {
    case (#none) {
           let rect = boundingRectOfElms(frame.elms.toArray());
           { width=rect.pos.x + rect.dim.width;
             height=rect.pos.y + rect.dim.height }
         };
    case (#flow(flow)) { dimOfFlow(frame.elms.toArray(), flow) };
    };
  };

  func boundingRectOfElm(elm:Elm) : Rect {
    Debug.print "boundingRectOfElm";
    switch elm {
      case (#node(node)) { node.rect };
      case (#rect(r, _)) { r };
    }
  };

  func boundingRectOfElms(elms:Elms) : Rect {
    Debug.print "boundingRectOfElms";
    let max_dim = 999999; // to do
    var min_x = max_dim;
    var min_y = max_dim;
    var max_width = 0;
    var max_height = 0;
    for (elm in elms.vals()) {
      let rect = boundingRectOfElm(elm);
      if (rect.pos.x < min_x) { min_x := rect.pos.x };
      if (rect.pos.y < min_y) { min_y := rect.pos.y };
      let w2 = rect.pos.x + rect.dim.width;
      let h2 = rect.pos.y + rect.dim.height;
      if (w2 > max_width) { max_width := w2 };
      if (h2 > max_height) { max_height := h2 };
    };
    {
      pos={
        x=min_x;
        y=min_y;
      };
      dim={
        width=max_width;
        height=max_height;
      }
    }
  };

  func repositionRect(r:Rect, _pos:Pos) : Rect {
    { pos=_pos; dim=r.dim }
  };

  func repositionElm(elm:Elm, pos:Pos) : Elm {
    switch elm {
      case (#rect(r, f)) {
             #rect(repositionRect(r, pos), f)
           };
      case (#node(n)) {
             #node{
               rect= repositionRect(n.rect, pos);
               fill= n.fill;
               elms= n.elms;
             }
           };
    }
  };

  func repositionFrameElms(frame: Frame) : (Elms, Rect) {
    Debug.print "repositionFrameElms";
    let frameDim = dimOfFrame(frame);
    var elmsOut = Buffer.Buffer<Elm>(0);
    var posOut = {x=0; y=0};
    switch (frame.typ) {
      case (#none) {
             elmsOut := frame.elms;
             let rect = boundingRectOfElms(frame.elms.toArray());
             posOut := rect.pos
           };
      case (#flow(flow)) {
             let p = flow.interPad;
             var nextPos = switch (flow.dir) {
               case (#right) { { x=p; y=p } };
               case (#down) { { x=p; y=p } };
               case (#left) { { x=p + frameDim.width;
                              y=p } };
               case (#up) { { x=p;
                            y=p + frameDim.height; } }
             };
             for (elm in frame.elms.vals()) {
               elmsOut.add(repositionElm(elm, nextPos));
               let dim = dimOfElm(elm);
               let p = flow.intraPad;
               nextPos := switch (flow.dir) {
               case (#right) {
                      {x=nextPos.x + dim.width + p;
                       y=nextPos.y }
                    };
               case (#down) {
                      {x=nextPos.x;
                       y=nextPos.y + dim.height + p}
                    };
               case (#left) {
                      {x=nextPos.x - (dim.width + p);
                       y=nextPos.y;}
                    };
               case (#up) {
                      {x=nextPos.x;
                       y=nextPos.y - (dim.height + p)}
                    };
               }
           }
           };
    };
    ( elmsOut.toArray(), {pos={x=0;y=0}; dim=frameDim} )
  };

  func elmOfFrame(frame:Frame) : Elm {
    Debug.print "elmOfFrame begin";
    let (elms_, rect_) = repositionFrameElms(frame);
    Debug.print "elmOfFrame done";
    #node{ rect= rect_;
           fill= frame.fill;
           elms= elms_;
    }
  };

  public class CharRender(r:Render, bdf : Char -> BitMapData, bta : BitMapTextAtts) {
    public var render = r;
    public var bitmapData = bdf;
    public var bitmapTextAtts = bta;
    public func char(c:Char) {
      render.bitmap(bitmapData c, bitmapTextAtts)
    };
    public func charAtts(c:Char, bta : BitMapTextAtts) {
      let saved = bitmapTextAtts;
      bitmapTextAtts := bta;
      char(c);
      bitmapTextAtts := saved;
    };
    public func charFg(c:Char, fgFill:Fill) {
      let saved = bitmapTextAtts;
      bitmapTextAtts := textAttsFg(bitmapTextAtts, fgFill);
      char(c);
      bitmapTextAtts := saved;
    };
    public func charBg(c:Char, fgFill:Fill, bgFill:Fill) {
      let saved = bitmapTextAtts;
      bitmapTextAtts := textAttsBg(bitmapTextAtts, fgFill, bgFill);
      char(c);
      bitmapTextAtts := saved;
    };
  };

  public class TextRender(cr:CharRender) {
    public var charRender = cr;
    public func text(t:Text) {
      charRender.render.bitmapText(
        cr.bitmapData,
        cr.bitmapTextAtts,
        t)
    };
    public func textAtts(t:Text, bta : BitMapTextAtts) {
      let saved = charRender.bitmapTextAtts;
      charRender.bitmapTextAtts := bta;
      text(t);
      charRender.bitmapTextAtts := saved;
    };
    public func textFg(t:Text, fgFill:Fill) {
      let saved = charRender.bitmapTextAtts;
      charRender.bitmapTextAtts := textAttsFg(charRender.bitmapTextAtts, fgFill);
      text(t);
      charRender.bitmapTextAtts := saved;
    };
    public func textBg(t:Text, fgFill:Fill, bgFill:Fill) {
      let saved = charRender.bitmapTextAtts;
      charRender.bitmapTextAtts := textAttsBg(charRender.bitmapTextAtts, fgFill, bgFill);
      text(t);
      charRender.bitmapTextAtts := saved;
    };
  };

}
