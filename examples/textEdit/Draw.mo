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

  func horzText(zoom : Nat) : Render.FlowAtts { {
    dir=#right;
    interPad=zoom;
    intraPad=zoom;
  } };

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

  func taTitleText(lineNo : Nat) : Atts =
    switch lineNo {
    case 0 {
           zoom=4;
           fgFill=#closed((255, 255, 255));
           bgFill=#closed((0, 0, 0));
         };
    case 1 {
           zoom=2;
           fgFill=#closed((220, 220, 220));
           bgFill=#closed((0, 0, 0));
         };
    case 2 {
           zoom=2;
           fgFill=#closed((150, 150, 150));
           bgFill=#closed((0, 0, 0));
         };
    case _ {
           zoom=3;
           fgFill=#closed((255, 255, 255));
           bgFill=#closed((0, 0, 0));
         };
  };

  func textAtts(fg : Render.Color) : Atts =
    attsFgBg(#closed(fg), #closed((0, 0, 0)));

  func cursorAtts(st : State) : Atts {
    switch (st.currentEvent) {
    case null {
           attsFgBg(#closed((255, 255, 255)), #closed((0, 0, 0)));
         };
    case (?ev) {
           attsFgBg(#closed(ev.userInfo.textColor.0), #closed((0, 0, 0)));
         };
    }
  };

  public func drawEvent(ev : Types.EventInfo) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar,
                               {
                                 zoom = 1;
                                 fgFill = #closed((255, 255, 255));
                                 bgFill = #closed((0, 0, 0));
                                 flow = horzText(1);
                               });
    let tr = Render.TextRender(cr);
    r.begin(#flow(vert));
    r.fill(#open((100, 100, 100), 1));
    r.begin(#flow(horz));
    tr.textAtts(ev.dateTimeUtc # " ", taTitleText(2));
    tr.textAtts(ev.userInfo.userName, taTitleText(2));
    r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
           #closed(ev.userInfo.textColor.0));
    r.rect({pos={x=0; y=0}; dim={width=10; height=10}}, #none);
    switch (ev.event) {
    case (#quit) tr.textAtts("quit", taTitleText(1));
    case (#skip) tr.textAtts("skip", taTitleText(1));
    case (#mouseDown(pos)) tr.textAtts("mouseDown(...)", taTitleText(1));
    case (#keyDown(ks)) {
           tr.textAtts("keyDown ", taTitleText(1));
           for (k in ks.vals()) {
             tr.textAtts(k.key # " ", taTitleText(2));
           };
         };
    case x { tr.textAtts("??? to do.", taTitleText(1)) };
    };
    r.end();
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  public func drawCommitLog(st : State) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar,
                        {
                          zoom = 1;
                          fgFill = #closed((255, 255, 255));
                          bgFill = #closed((0, 0, 0));
                          flow = horzText(1);
                        });
    let tr = Render.TextRender(cr);
    r.begin(#flow(vert));
    r.fill(#open((255, 255, 0), 1));
    {
      tr.textAtts("Developer view", taTitleText(1));
      {
        r.begin(#flow(vert));
        tr.textAtts(" Commit log:", taTitleText(1));
        r.begin(#flow(vert));
        for (ev in st.commitLog.vals()) {
          r.elm(drawEvent(ev));
        };
        r.end();
        switch (st.currentEvent) {
          case null { };
          case (?ev) {
                 r.begin(#flow(horz));
                 tr.textAtts(" View for ", taTitleText(1));
                 tr.textAtts(ev.userInfo.userName, taTitleText(1));
                 r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
                        #closed(ev.userInfo.textColor.0));
                 r.end()
               }
        };
        r.begin(#flow(vert));
        for (ev in st.viewEvents.vals()) {
          r.elm(drawEvent(ev));
        };
        r.end();
        r.end();
      };
    };
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  public func drawState(st : State, windowDim : Render.Dim) : Render.Elm {

    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar,
                        {
                          zoom = 3;
                          fgFill = #closed((255, 255, 255));
                          bgFill = #closed((0, 0, 0));
                          flow = horzText(3);
                        });
    let tr = Render.TextRender(cr);

    r.begin(#flow(horz));  // Outer Display begin
    r.begin(#flow(vert));  // Inner Display begin
    r.fill(#open((255, 255, 0), 1));

    {
      r.begin(#flow(vert));
      r.fill(#open((255, 255, 255), 1));
      {
        tr.textAtts("IC-EDIT", taTitleText(0));
        tr.textAtts(" a multi-user text editor,", taTitleText(1));
        tr.textAtts(" via Motoko and the Internet Computer", taTitleText(2));
        tr.textAtts("-------------------------------------", taTitleText(2));
      };
      {
        r.begin(#flow(horz));
        tr.textAtts("User ", taTitleText(3));
        switch (st.currentEvent) {
          case null tr.textAtts("?", taTitleText(3));
          case (?ev) {
                 tr.textAtts(ev.userInfo.userName, taTitleText(3));
               };
        };
        switch (st.currentEvent) {
          case null { };
          case (?ev) {
                 tr.textAtts(" as ", taTitleText(2));
                 // draw a rectangle with their text color, a la Etherpad UI.
                 r.rect({pos={x=0; y=0}; dim={width=15; height=15}},
                        #closed(ev.userInfo.textColor.0));
               };
        };
        r.end();
      };
      {
        func getContentInfo(elm : ?Types.Elm) : (Text, Text, Render.Color) = {
          switch elm {
          case null ("none", "no one", (0, 0, 0));
          case (?(#text(te))) { (te.lastModifyTime, te.lastModifyUser, te.color) };
          }
        };
        let ((timeBefore, userBefore, colorBefore),
             (timeAfter, userAfter, colorAfter)) = (
          getContentInfo(Seq.peekBack(st.bwd)),
          getContentInfo(Seq.peekFront(st.fwd)),
        );
        {
          r.begin(#flow(vert));
          tr.textAtts("Meta info: ", taTitleText(2));
          {
            r.begin(#flow(horz));
            tr.textAtts("* back: ", taTitleText(2));
            tr.textAtts(timeBefore, taTitleText(2));
            tr.textAtts(" by ", taTitleText(2));
            tr.textAtts(userBefore, taTitleText(2));
            r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
                   #closed(colorBefore));
            r.end();
          };
          {
            r.begin(#flow(horz));
            tr.textAtts("* forw: ", taTitleText(2));
            tr.textAtts(timeAfter, taTitleText(2));
            tr.textAtts(" by ", taTitleText(2));
            tr.textAtts(userAfter, taTitleText(2));
            r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
                   #closed(colorAfter));
            r.end();
          };
          r.end();
        };
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
                 tr.textAtts(te.text, textAtts(te.color));
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
      tr.textAtts("*", cursorAtts(st));
      for (line in Seq.iter(linesAfter, #fwd)) {
        for (elm in Seq.iter(line, #fwd)) {
          switch elm {
          case (#text(te)) {
                 tr.textAtts(te.text, textAtts(te.color));
               };
          };
        };
        r.end();
        r.begin(#flow(horz));
      };
      r.end();
    };
    r.end(); // Vertical end
    r.end(); // Inner Display end

    r.elm(drawCommitLog(st)); // Commit log, for developers.

    r.end(); // Outer Display end
    r.getElm()
  };

}
