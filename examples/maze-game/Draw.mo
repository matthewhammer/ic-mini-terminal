import List "mo:base/List";
import Result "mo:base/Result";

import Render "../../src/Render";
import Mono5x5 "../../src/glyph/Mono5x5";
import Types "Types";

module {

  type State = Types.State;
  type TextAtts = Render.BitMapTextAtts;

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

  // Text atts --------------------------------------------------------

  func tileAtts(fg:Render.Fill, bg:Render.Fill) : TextAtts {
    {
      zoom=4;
      fgFill=fg;
      bgFill=bg;
      flow=horz;
    }
  };

  func taLegend(fg:Render.Fill) : TextAtts {
    {
      zoom=2;
      fgFill=fg;
      bgFill=#closed((0, 0, 0));
      flow=textHorz;
    }
  };

  func taLegendTextLo() : TextAtts =
    taLegend(#closed((180, 140, 190)));
  
  func taLegendTextHi() : TextAtts =
    taLegend(#closed((220, 200, 240)));

  func taTitleText() : TextAtts =
    taLegend(#closed((240, 200, 255)));

  // Fill names --------------------------------------------------------

  func bgFill() : Render.Fill = #closed((50, 10, 50));
  func bgFillHi() : Render.Fill = #closed((150, 100, 150));
  func taVoid() : TextAtts = tileAtts(#none, #none);
  func taPlayer() : TextAtts = tileAtts(#closed((255, 255, 255)), bgFill());
  func taStart() : TextAtts = tileAtts(#closed((255, 100, 255)), bgFill());
  func taGoal() : TextAtts = tileAtts(#closed((255, 255, 255)), bgFillHi());
  func taWall() : TextAtts = tileAtts(#closed((150, 100, 200)), bgFill());
  func taFloor() : TextAtts = tileAtts(#closed((200, 100, 200)), bgFill());
  func taLock() : TextAtts = tileAtts(#closed((200, 200, 100)), bgFill());
  func taKey() : TextAtts = tileAtts(#closed((255, 255, 100)), bgFill());

  // --------------------------------------------------------

  public func drawState(st:State) : Render.Elm {

    let r = Render.Render();
    
    func text(txt : Text, atts : TextAtts) {
      let cr = Render.CharRender(r, Mono5x5.bitmapOfChar, atts);
      let tr = Render.TextRender(cr);
      tr.textAtts(txt, atts)
    };

    let room_tiles = st.maze.rooms[st.pos.room].tiles;

    r.begin(#flow(vert)); // Display begin
    r.fill(#open((200, 255, 200), 1));

    // Title line:
    if (st.won) {
      r.begin(#flow(horz));
      text("MazeGame: Game over, You won!!", taTitleText());
      r.end();
    } else {
      r.begin(#flow(horz));
      text("MazeGame in Motoko!", taTitleText());
      r.end();
    };

    r.begin(#flow(horz)); // Inner-display begin

    r.begin(#flow(vert)); // Legend begin

    r.begin(#flow(vert));
    r.begin(#flow(horz));
    text("room:", taLegendTextLo());
    r.end();
    r.begin(#flow(horz));
    r.begin(#flow(vert));
    text(debug_show st.pos.room, taLegendTextHi());
    r.end();
    r.end();

    r.begin(#flow(horz));
    text("tile:", taLegendTextLo());
    r.end();
    r.begin(#flow(horz));
    r.begin(#flow(vert));
    text("(", taLegendTextLo());
    r.end();
    r.begin(#flow(vert));
    text(debug_show st.pos.tile.1, taLegendTextHi());
    r.end();
    r.begin(#flow(vert));
    text(",", taLegendTextLo());
    r.end();
    r.begin(#flow(vert));
    text(debug_show st.pos.tile.0, taLegendTextHi());
    r.end();
    r.begin(#flow(vert));
    text(")", taLegendTextLo());
    r.end();
    r.end();

    r.begin(#flow(vert)); // Keys begin
    text("keys:", taLegendTextLo());
    r.end();
    r.begin(#flow(horz));
    switch (st.keys) {
      case null { text("none", taLegendTextHi()) };
      case (?_) {
             List.iterate<()>(st.keys,
               func (_:()) {
                 r.begin(#flow(vert));
                 text("ķ", taLegend(#closed((255, 255, 100))));
                 r.end();
               })
           };
    };
    r.end();
    r.end(); // Keys end
    r.end(); // Legend end

    r.begin(#flow(vert)); // Map begin
    var i = 0;
    for (row in room_tiles.vals()) {
      var j = 0;
      r.begin(#flow(horz));
      for (tile in row.vals()) {
        r.begin(#flow(horz));
        if (j == st.pos.tile.0
        and i == st.pos.tile.1) {
          text("☺", taPlayer())
        } else {
          switch tile {
          case (#void) { text(" ", taVoid()) };
          case (#start) { text("◊", taStart()) };
          case (#goal) { text("⇲", taGoal()) };
          case (#floor) { text(" ", taFloor()) };
          case (#wall) { text("█", taWall()) };
          case (#lock(_)) { text("ļ", taLock()) };
          case (#key(_)) { text("ķ", taKey()) };
          case (#inward(_)) { text("◊", taWall()) };
          case (#outward(_)) { text("⇲", taWall()) };
          };
        };
        r.end();
        j += 1;
      };
      r.end();
      i += 1;
    };
    r.end(); // Map end
    r.end(); // Inner-display end
    r.end(); // Display end
    r.getElm()
  };

}
