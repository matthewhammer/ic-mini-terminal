import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Mono5x5 "mo:redraw/glyph/Mono5x5";
import Types "Types";

import TextSeq "mo:sequence/Text";
import Seq "mo:sequence/Sequence";
import Stream "mo:sequence/Stream";

module {

  public type State = Types.State;

  // Flow atts --------------------------------------------------------

  let horz : Render.FlowAtts = {
    dir=#right;
    interPad=1;
    intraPad=1;
  };

  let vert : Render.FlowAtts = {
    dir=#down;
    interPad=1;
    intraPad=1;
  };

  let textHorz : Render.FlowAtts = {
    dir=#right;
    interPad=1;
    intraPad=1;
  };

  // Char/Text atts --------------------------------------------------------

  type Atts = {
    zoom:Nat;
    fgFill:Render.Fill;
    bgFill:Render.Fill
  };

  func attsFgBg(fg:Render.Fill, bg:Render.Fill) : Atts =
    {
      zoom=4;
      fgFill=fg;
      bgFill=bg;
    };

  func attsLegendFg(fg:Render.Fill) : Atts =
    {
      zoom=2;
      fgFill=fg;
      bgFill=#closed((0, 0, 0));
    };

  func attsLegendTextLo() : Atts =
    attsLegendFg(#closed((180, 140, 190)));

  func attsLegendTextHi() : Atts =
    attsLegendFg(#closed((220, 200, 240)));

  func taTitleText(lineNo : Nat) : Atts =
    switch lineNo {
    case 0 {
           zoom=4;
           fgFill=#closed((60, 255, 100));
           bgFill=#closed((60, 0, 60));
         };
    case 1 {
           zoom=2;
           fgFill=#closed((160, 255, 200));
           bgFill=#closed((0, 0, 0));
         };
    case 2 {
           zoom=2;
           fgFill=#closed((60, 255, 100));
           bgFill=#closed((60, 0, 60));
         };
    case _ {
           zoom=3;
           fgFill=#closed((255, 255, 255));
           bgFill=#closed((60, 0, 60));
         };
  };

  func userTextAtts(st : State) : Atts =
    attsFgBg(#closed(st.init.userTextColor), #closed((0, 0, 0)));

  func cursorAtts() : Atts =
    attsFgBg(#closed((200, 250, 200)), #closed((0, 0, 0)));

  // Fill / Atts names --------------------------------------------------------

  func bgFill() : Render.Fill = #closed((50, 10, 50));
  func bgFillHi() : Render.Fill = #closed((150, 100, 150));

  // --------------------------------------------------------

  public func drawState(st : State, windowDim : Render.Dim) : Render.Elm {

    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar,
                        {
                          zoom = 3;
                          fgFill = #closed((255, 255, 255));
                          bgFill = #closed((0, 0, 0));
                          flow = horz
                        });
    let tr = Render.TextRender(cr);

    r.begin(#flow(vert)); // Display begin
    r.fill(#open((255, 255, 0), 1));

    {
      r.begin(#flow(vert));
      r.fill(#open((255, 255, 255), 1));
      {
        r.begin(#flow(horz));
        tr.textAtts("TextEdit", taTitleText(0));
        tr.textAtts("Multi-user text editor (in Motoko, for the IC)", taTitleText(1));
        r.end();
      };
      { 
        r.begin(#flow(horz));
        tr.textAtts("Username: ", taTitleText(2));
        tr.textAtts(st.init.userName, taTitleText(3));
        r.end();
      };
      r.end();
    };
    func isNewline(elm : Types.Elm) : Bool = {
      switch elm {
        case (#text(te)) { te.text == "\n" };
      }
    };
    let (linesBefore, linesAfter) = (
      Seq.tokens(st.bwd, isNewline, st.levels),
      Seq.tokens(st.fwd, isNewline, st.levels),
    );
    r.begin(#flow(vert));
    {
      r.begin(#flow(horz));
      for (line in Seq.iter(linesBefore, #fwd)) {
        r.end();
        r.begin(#flow(horz));
        for (elm in Seq.iter(line, #fwd)) {
          switch elm {
          case (#text(te)) {
                 tr.textAtts(te.text, userTextAtts(st));
               };
          };
        };
      };
      // edge case: newline char is immediately to left of cursor (begin next line)
      switch (Seq.peekBack(st.bwd)) {
      case (?lastChar) {
             if (isNewline(lastChar)) {
               r.end();
               r.begin(#flow(horz));
             };
           };
      case _ { };
      };
      tr.textAtts("*", cursorAtts());
      for (line in Seq.iter(linesAfter, #fwd)) {
        for (elm in Seq.iter(line, #fwd)) {
          switch elm {
          case (#text(te)) {
                 tr.textAtts(te.text, userTextAtts(st));
               };
          };
        };
        r.end();
        r.begin(#flow(horz));
      };
      r.end();
    };
    r.end(); // Vertical end
    r.end(); // Display end
    r.getElm()
  };

}
