import Result "mo:base/Result";
import List "mo:base/List";
import Render "mo:redraw/Render";
import Types "Types";
import TextSeq "mo:sequence/Text";

module {
  type State = Types.State;

  public func keyDown(st:State, key:Types.KeyInfo) {
    switch (key.key) {
      case "ArrowLeft"  move(st, #left);
      case "ArrowRight" move(st, #right);
      case "ArrowUp"    move(st, #up);
      case "ArrowDown"  move(st, #down);
      case _  { };
    };
  };

  public func clone(st : State) : State {
    // sharing is okay, because of immutable rep
    { var text : TextSeq.TextSeq = st.text; }
  };

  public func move(st : State, dir : Types.Dir2D) {
    // to do
  };
  
  public func keyDownSeq(st:State, keys:[Types.KeyInfo]) {
    for (key in keys.vals()) { keyDown(st, key) };
  };

  public func initState() : Types.State {
     { var text : TextSeq.TextSeq = #empty; }
  };
}
