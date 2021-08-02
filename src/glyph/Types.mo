import Types "../Types";

module {
  public type FlowAtts = {
    dir: Dir2D;
    intraPad: Nat;
    interPad: Nat;
  };

  public type Dir2D = {#up; #down; #left; #right};

  public type Fill = Types.Graphics.Fill;

  public type BitMapData = {
    dim: Types.Dim;
    bits: [[Bool]];
  };

  public type BitMapAtts = {
    zoom: Nat;
    fgFill: Fill;
    bgFill: Fill;
  };

  public type BitMapTextAtts = {
    zoom: Nat;
    fgFill: Fill;
    bgFill: Fill;
    flow: FlowAtts;
  };
}
