import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";

import TextSeq "mo:sequence/Text";
import Seq "mo:sequence/Sequence";

module {

public type Dir2D = {
  #up;
  #down;
  #left;
  #right
};

public type KeyInfo = {
  key : Text;
  alt : Bool;
  ctrl : Bool;
  meta: Bool;
  shift: Bool
};

public type State = {
   var text : TextSeq.TextSeq;
};

// move results back to game client:
public type ResOut = Result.Result<Render.Out, Render.Out>;

}
