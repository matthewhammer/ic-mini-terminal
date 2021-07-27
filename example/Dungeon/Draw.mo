import Render "mo:redraw/Render";
import Mono5x5 "mo:redraw/glyph/Mono5x5";

import Types "Types";

module {

  type State = Types.State;

  // (Spacing for blocks)-------------------------------------

  let horz : Render.FlowAtts = {
    dir=#right;
    interPad=2;
    intraPad=2;
  };

  let vert : Render.FlowAtts = {
    dir=#down;
    interPad=2;
    intraPad=2;
  };

  let tinyHorz : Render.FlowAtts = {
    dir=#right;
    interPad=1;
    intraPad=1;
  };

  let tinyVert : Render.FlowAtts = {
    dir=#down;
    interPad=1;
    intraPad=1;
  };

  func horzText(zoom : Nat) : Render.FlowAtts { {
    dir=#right;
    interPad=zoom;
    intraPad=zoom;
  } };

  // (Color and spacing for text)--------------------------------------------

  type Atts = Render.BitMapTextAtts;

  type TxtElm = {#colorZoom:((Nat, Nat, Nat), Nat); #lo; #vlo; #hi; #h4; #h3};

  func txtSty(txtElm : TxtElm) : Atts {
    switch txtElm {
    case (#colorZoom(c, z)) { {
           zoom=z;
           fgFill=#closed(c);
           bgFill=#none;
           flow=horzText(z);
         } };
    case (#vlo) { {
           zoom=1;
           fgFill=#closed((100, 100, 100));
           bgFill=#none;
           flow=horzText(1);
         } };
    case (#lo) { {
           zoom=1;
           fgFill=#closed((200, 200, 200));
           bgFill=#none;
           flow=horzText(1);
         } };
    case (#hi) { {
           zoom=1;
           fgFill=#closed((240, 240, 240));
           bgFill=#none;
           flow=horzText(1);
         } };
    case (#h3) { {
           zoom=2;
           fgFill=#closed((250, 250, 250));
           bgFill=#none;
           flow=horzText(2);
         } };
    case (#h4) { {
           zoom=2;
           fgFill=#closed((200, 200, 200));
           bgFill=#none;
           flow=horzText(2);
         } };
    }
  };

  func drawUsers(st : State) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);
    r.begin(#flow(horz));
    r.begin(#flow(vert));
    do {
      r.begin(#flow(horz));
      tr.textAtts("Users online:", txtSty(#h3));
      r.end();
      for ((user, userSt) in st.users.entries()) {
        r.begin(#flow(horz));
        r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
               #closed(userSt.textColor));
        tr.textAtts(user # " @ ", txtSty(#h4));
        tr.textAtts(userSt.lastEventTime, txtSty(#lo));
        r.end()
      }
    };
    r.end();    
    r.end();
    r.getElm()
  };

  func drawMainWindow(st : State, windowDim : Render.Dim) : Render.Elm {
    let r = Render.Render();
    r.begin(#flow(vert));
    r.elm(drawUsers(st));
    r.end();
    r.getElm()
  };

  public func drawState(st : State, windowDim : Render.Dim) : Render.Elm {
    drawMainWindow(st, windowDim)
  };

}
