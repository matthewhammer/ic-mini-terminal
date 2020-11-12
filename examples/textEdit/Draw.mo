import List "mo:base/List";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Mono5x5 "mo:redraw/glyph/Mono5x5";
import Types "Types";

import TextSeq "mo:sequence/Text";
import Seq "mo:sequence/Sequence";
import Stream "mo:sequence/Stream";

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

  type TxtElm = {#colorZoom:((Nat, Nat, Nat), Nat); #lo; #vlo; #hi; #h3};

  func txtSty(txtElm : TxtElm) : Atts = {
    switch txtElm {
    case (#colorZoom(c, z)) {
           zoom=z;
           fgFill=#closed(c);
           bgFill=#none;
           flow=horzText(z);
         };
    case (#vlo) {
           zoom=1;
           fgFill=#closed((100, 100, 100));
           bgFill=#none;
           flow=horzText(1);
         };
    case (#lo) {
           zoom=1;
           fgFill=#closed((200, 200, 200));
           bgFill=#none;
           flow=horzText(1);
         };
    case (#hi) {
           zoom=1;
           fgFill=#closed((240, 240, 240));
           bgFill=#none;
           flow=horzText(1);
         };
    case (#h3) {
           zoom=2;
           fgFill=#closed((250, 250, 250));
           bgFill=#none;
           flow=horzText(2);
         };
    }
  };

  func cursorAtts(st : State) : Atts {
    switch (st.currentEvent) {
    case null { txtSty(#colorZoom((255, 255, 255), 2)) };
    case (?ev) { txtSty(#colorZoom(ev.userInfo.textColor.0, 2)) };
    }
  };

  /// -----------------------------------------------
  func drawEvent(ev : Types.EventInfo) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);
    r.begin(#flow(vert));
    r.fill(#open((60, 20, 60), 1));
    r.begin(#flow(horz));
    tr.textAtts(ev.dateTimeUtc # " ", txtSty(#lo));
    tr.textAtts(ev.userInfo.userName, txtSty(#lo));
    r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
           #closed(ev.userInfo.textColor.0));
    r.rect({pos={x=0; y=0}; dim={width=10; height=10}}, #none);
    switch (ev.event) {
    case (#quit) tr.textAtts("quit", txtSty(#lo));
    case (#skip) tr.textAtts("skip", txtSty(#lo));
    case (#mouseDown(pos)) tr.textAtts("mouseDown(...)", txtSty(#lo));
    case (#keyDown(ks)) {
           tr.textAtts("keyDown ", txtSty(#lo));
           for (k in ks.vals()) {
             if (k.shift) { tr.textAtts("Shift-", txtSty(#vlo)); };
             if (k.ctrl) { tr.textAtts("Ctrl-", txtSty(#vlo)); };
             if (k.alt) { tr.textAtts("Alt-", txtSty(#vlo)); };
             if (k.meta) { tr.textAtts("Meta-", txtSty(#vlo)); };
             tr.textAtts(k.key , txtSty(#lo));
           };
         };
    case x { tr.textAtts("??? to do.", txtSty(#lo)) };
    };
    r.end();
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  func drawCommitLog(st : State) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);
    r.begin(#flow(vert));
    r.fill(#open((200, 100, 220), 1));
    {
      tr.textAtts("Developer view", txtSty(#lo));
      {
        r.begin(#flow(vert));
        tr.textAtts("Commit log:", txtSty(#lo));
        r.begin(#flow(horz));
        r.rect({pos={x=0; y=0}; dim={width=10; height=10}}, #none);
        r.begin(#flow(vert));

        let maxShown = 8;

        var i =
          if (st.commitLog.size() > maxShown) st.commitLog.size() - maxShown
          else 0;

        let evs =
          List.reverse(
            List.take(
              List.reverse(
                Iter.toList(st.commitLog.vals())
              ),
              maxShown)
          );

        if (i != 0) {
          r.begin(#flow(horz));
          {
            tr.textAtts(Nat.toText(st.commitLog.size() - maxShown), txtSty(#hi));
            tr.textAtts(" earlier events, followed by...", txtSty(#lo));
          };
          r.end();
        };
        for (ev in Iter.fromList(evs)) {
          i += 1;
          r.begin(#flow(horz));
          r.begin(#flow(horz));
          r.fill(#open((100, 100, 100), 1));
          r.begin(#flow(horz));
          r.fill(#open((10, 10, 10), 1));
          tr.textAtts(Nat.toText(i), txtSty(#lo));
          r.end();
          r.end();
          r.elm(drawEvent(ev));
          r.end();
        };
        r.end();
        r.end();
        switch (st.currentEvent) {
          case null { };
          case (?ev) {
                 r.begin(#flow(horz));
                 tr.textAtts("View for ", txtSty(#lo));
                 tr.textAtts(ev.userInfo.userName, txtSty(#lo));
                 r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
                        #closed(ev.userInfo.textColor.0));
                 r.end()
               }
        };
        r.begin(#flow(horz));
        r.rect({pos={x=0; y=0}; dim={width=10; height=10}}, #none);
        r.begin(#flow(vert));
        for (ev in st.viewEvents.vals()) {
          r.elm(drawEvent(ev));
        };
        r.end();
        r.end();
        r.end();
      };
    };
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  func drawUsers(st : State) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);

    r.begin(#flow(vert));
    {
      r.begin(#flow(horz));
      {
        tr.textAtts("Editing now as ", txtSty(#lo));
        switch (st.currentEvent) {
        case null tr.textAtts("?", txtSty(#lo));
        case (?ev) {
               tr.textAtts(ev.userInfo.userName, txtSty(#lo));
             };
        };
        switch (st.currentEvent) {
        case null { };
        case (?ev) {
               tr.textAtts(" with ", txtSty(#lo));
               // draw a rectangle with their text color, a la Etherpad UI.
               r.rect({pos={x=0; y=0}; dim={width=15; height=15}},
                      #closed(ev.userInfo.textColor.0));
             };
        };
      };
      r.end();


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

      r.begin(#flow(tinyVert));
      {
        tr.textAtts("Content info: ", txtSty(#lo));
        {
          r.begin(#flow(tinyHorz));
          {
            tr.textAtts("* before cursor: ", txtSty(#lo));
            tr.textAtts(timeBefore, txtSty(#hi));
            tr.textAtts(" by ", txtSty(#lo));
            tr.textAtts(userBefore, txtSty(#hi));
            r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
                   #closed(colorBefore));
          };
          r.end();
        };
        r.begin(#flow(tinyHorz));
        {
          tr.textAtts("* after cursor: ", txtSty(#lo));
          tr.textAtts(timeAfter, txtSty(#hi));
          tr.textAtts(" by ", txtSty(#lo));
          tr.textAtts(userAfter, txtSty(#hi));
          r.rect({pos={x=0; y=0}; dim={width=10; height=10}},
                 #closed(colorAfter));
        };
        r.end();
      };
      r.end();
    };
    r.end();
    r.getElm()
  };

  /// -----------------------------------------------
  func drawContent(st : State) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);

    func isNewline(elm : Types.Elm) : Bool = {
      switch elm {
        case (#text(te)) { te.text == "\n" };
      }
    };

    let (linesBefore, linesAfter) = (
      Seq.tokens(st.bwd, isNewline, st.levels),
      Seq.tokens(st.fwd, isNewline, st.levels),
    );

    r.begin(#flow(horz));
    r.fill(#open((200, 200, 200), 1));
    {
    r.begin(#flow(vert));
    {
      // draw the text buffer content, including the visible cursor(s)
      r.begin(#flow(horz));
      for (line in Seq.iter(linesBefore, #fwd)) {
        r.end();
        r.begin(#flow(horz));
        for (elm in Seq.iter(line, #fwd)) {
          switch elm {
          case (#text(te)) {
                 tr.textAtts(te.text, txtSty(#colorZoom(te.color, 2)));
               };
          };
        };
      };
      {
        /* detect an edge case: (to do: another "view representation" that obviates this logic.)
           newline char is immediately to left of cursor.
           if so, put cursor on next line, not dangling after (invisible) newline char. */
        switch (Seq.peekBack(st.bwd)) {
        case (?lastChar) {
               if (isNewline(lastChar)) {
                 r.end();
                 r.begin(#flow(horz));
               };
             };
        case _ { };
        };
      };
      tr.textAtts("*", cursorAtts(st));
      for (line in Seq.iter(linesAfter, #fwd)) {
        for (elm in Seq.iter(line, #fwd)) {
          switch elm {
          case (#text(te)) {
                 tr.textAtts(te.text, txtSty(#colorZoom(te.color, 2)));
               };
          };
        };
        r.end();
        r.begin(#flow(horz));
      };
      r.end();
    };
    r.end(); // Vertical end
    };
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  func drawTitle(st : State) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);

    r.begin(#flow(vert));
    r.fill(#open((255, 255, 0), 1));
    {
      r.begin(#flow(vert));
      r.fill(#open((255, 255, 255), 1));
      {
        tr.textAtts("IC-EDIT", txtSty(#lo));
        tr.textAtts(" a multi-user text editor,", txtSty(#lo));
        tr.textAtts(" via Motoko and the Internet Computer", txtSty(#lo));
      };
      r.end();
    };
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  func drawMainWindow(st : State, windowDim : Render.Dim) : Render.Elm {
    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, txtSty(#lo));
    let tr = Render.TextRender(cr);

    r.begin(#flow(vert)); // Two rows in view, each with two "blocks":
    {
      r.begin(#flow(horz)); // Row 1: Title block and Users block
      {
        r.elm(drawTitle(st));
        r.elm(drawUsers(st)); // All users.
      };
      r.end();
      r.begin(#flow(horz)); // Row 2: Content block and Developer info (events)
      {
        r.elm(drawContent(st));
        r.elm(drawCommitLog(st));
      };
      r.end();
    };
    r.end();
    r.getElm()
  };

  /// --------------------------------------------------------------------
  public func drawState(st : State, windowDim : Render.Dim) : Render.Elm {
    drawMainWindow(st, windowDim)
  };

}
