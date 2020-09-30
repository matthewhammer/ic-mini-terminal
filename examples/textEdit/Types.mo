import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";

import TextSeq "mo:sequence/Text";
import Seq "mo:sequence/Sequence";
import Stream "mo:sequence/Stream";

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

public type Elm = {
  #text : Text
  // more later
};

public type Levels = Seq.Stream<Stream.Bernoulli.Value>;
public type TextSeq = TextSeq.TextSeq;

public type State = {
  levels : Levels;
  var fwd : TextSeq;
  var bwd : TextSeq;
};

// move results back to game client:
public type ResOut = Result.Result<Render.Out, Render.Out>;

}
