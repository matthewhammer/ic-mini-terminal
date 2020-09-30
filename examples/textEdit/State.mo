import Result "mo:base/Result";
import List "mo:base/List";
import Render "mo:redraw/Render";
import Types "Types";
import TextSeq "mo:sequence/Text";
import Debug "mo:base/Debug";

module {
  type State = Types.State;

  public func keyDown(st:State, key:Types.KeyInfo) {
    switch (key.key) {
      case "ArrowLeft"  move(st, #left);
      case "ArrowRight" move(st, #right);
      case "ArrowUp"    move(st, #up);
      case "ArrowDown"  move(st, #down);
      case "BackSpace"  delete(st, #bwd);
      case "Delete"     delete(st, #fwd);
      case "A" insert(st, #text("A"));
      case "a" insert(st, #text("a"));
      case "B" insert(st, #text("B"));
      case "b" insert(st, #text("b"));
      case "C" insert(st, #text("C"));
      case "c" insert(st, #text("c"));
      case _ { };
    };
  };

  public func keyDownSeq(st:State, keys:[Types.KeyInfo]) {
    for (key in keys.vals()) { keyDown(st, key) };
  };

  public func initState() : Types.State {
     { var text : TextSeq.TextSeq = #empty; }
  };

  public func clone(st : State) : State {
    // sharing is okay, because of immutable rep
    { var text : TextSeq.TextSeq = st.text; }
  };

  // to do ---------------------------------------

  func move(st : State, dir : Types.Dir2D) {
    Debug.print ("State.move" # debug_show dir);
    // to do
  };

  func insert(st : State, elm : Types.Elm) {
    Debug.print ("State.insert" # debug_show elm);
    // to do
  };

  func delete(st : State, dir : {#fwd; #bwd}) {
    Debug.print ("State.delete" # debug_show dir);
    // to do
  };

}
