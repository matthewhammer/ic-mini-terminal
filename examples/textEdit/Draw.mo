import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Mono5x5 "mo:redraw/glyph/Mono5x5";
import Types "Types";

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

  func taTitleText() : Atts =
    attsLegendFg(#closed((240, 200, 255)));

  // Fill / Atts names --------------------------------------------------------

  func bgFill() : Render.Fill = #closed((50, 10, 50));
  func bgFillHi() : Render.Fill = #closed((150, 100, 150));

  // --------------------------------------------------------

  public func drawState(st:State, isQueryView:Bool) : Render.Elm {

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
    r.fill(
      if isQueryView
        #open((200, 255, 200), 1)
      else
        #open((255, 255, 0), 1)
    );

    // Title line:
    let queryViewMsg = if isQueryView " (q)" else "";
    
    r.begin(#flow(horz));
    tr.textAtts("Hello world" # queryViewMsg, taTitleText());
    r.end();

    r.end(); // Display end
    r.getElm()
  };

}
