import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Mono5x5 "mo:redraw/glyph/Mono5x5";
import Types "Types";

module {

  type State = Types.State;

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

  func taTitleText() : Atts =
    attsLegendFg(#closed((240, 200, 255)));

  // Fill / Atts names --------------------------------------------------------

  func bgFill() : Render.Fill = #closed((50, 10, 50));
  func bgFillHi() : Render.Fill = #closed((150, 100, 150));
  func taVoid() : Atts = attsFgBg(#none, #none);
  func taPlayer() : Atts = attsFgBg(#closed((255, 255, 255)), bgFill());
  func taStart() : Atts = attsFgBg(#closed((255, 100, 255)), bgFill());
  func taGoal() : Atts = attsFgBg(#closed((255, 255, 255)), bgFillHi());
  func taWall() : Atts = attsFgBg(#closed((150, 100, 200)), bgFill());
  func taFloor() : Atts = attsFgBg(#closed((200, 100, 200)), bgFill());
  func taLock() : Atts = attsFgBg(#closed((200, 200, 100)), bgFill());
  func taKey() : Atts = attsFgBg(#closed((255, 255, 100)), bgFill());

  // --------------------------------------------------------

  public func drawState(st:State, playerId:Nat, isQueryView:Bool) : Render.Elm {
    assert(playerId >= 1);

    let r = Render.Render();
    let cr = Render.CharRender(r, Mono5x5.bitmapOfChar,
                        {
                          zoom = 3;
                          fgFill = #closed((255, 255, 255));
                          bgFill = #closed((0, 0, 0));
                          flow = horz
                        });
    let tr = Render.TextRender(cr);

    let pst = st.player[playerId - 1];
    let room_tiles = st.maze.rooms[pst.pos.room].tiles;
    
    r.begin(#flow(vert)); // Display begin
    r.fill(
      if isQueryView
        #open((200, 255, 200), 1)
      else
        #open((255, 255, 0), 1)
    );

    // Title line:
    let queryViewMsg = if isQueryView " (q)" else "";
    if (st.won) {
      r.begin(#flow(horz));
      tr.textAtts("mazegame: game over, you won!!" # queryViewMsg, taTitleText());
      r.end();
    } else {
      r.begin(#flow(horz));
      tr.textAtts("mazegame in motoko!" # queryViewMsg, taTitleText());
      r.end();
    };

    r.begin(#flow(horz)); // Inner-display begin

    r.begin(#flow(vert)); // Legend begin

    r.begin(#flow(vert));
    r.begin(#flow(horz));
    tr.textAtts("room:", attsLegendTextLo());
    r.end();
    r.begin(#flow(horz));
    r.begin(#flow(vert));
    tr.textAtts(debug_show pst.pos.room, attsLegendTextHi());
    r.end();
    r.end();

    r.begin(#flow(horz));
    tr.textAtts("tile:", attsLegendTextLo());
    r.end();
    r.begin(#flow(horz));
    r.begin(#flow(vert));
    tr.textAtts("(", attsLegendTextLo());
    r.end();
    r.begin(#flow(vert));
    tr.textAtts(debug_show pst.pos.tile.1, attsLegendTextHi());
    r.end();
    r.begin(#flow(vert));
    tr.textAtts(",", attsLegendTextLo());
    r.end();
    r.begin(#flow(vert));
    tr.textAtts(debug_show pst.pos.tile.0, attsLegendTextHi());
    r.end();
    r.begin(#flow(vert));
    tr.textAtts(")", attsLegendTextLo());
    r.end();
    r.end();

    r.begin(#flow(vert)); // Keys begin
    tr.textAtts("keys:", attsLegendTextLo());
    r.end();
    r.begin(#flow(horz));
    switch (pst.keys) {
      case null { tr.textAtts("none", attsLegendTextHi()) };
      case (?_) {
             List.iter<Types.KeyUser>(pst.keys,
               func (x:Types.KeyUser) {
                 r.begin(#flow(vert));
                 tr.textAtts("ķ", attsLegendFg(#closed((255, 255, 100))));
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
        if (j == pst.pos.tile.0
        and i == pst.pos.tile.1) {
          tr.textAtts("☺", taPlayer())
        } else {
          switch tile {
          case (#void) { tr.textAtts(" ", taVoid())  };
          case (#start) { tr.textAtts("◊", taStart()) };
          case (#goal) { tr.textAtts("⇲", taGoal()) };
          case (#floor) { tr.textAtts(" ", taFloor()) };
          case (#wall) { tr.textAtts("█", taWall()) };
          case (#lock(_)) { tr.textAtts("ļ", taLock()) };
          case (#key(_)) { tr.textAtts("ķ", taKey()) };
          case (#inward(_)) { tr.textAtts("◊", taWall()) };
          case (#outward(_)) { tr.textAtts("⇲", taWall()) };
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
