import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";

import TextSeq "mo:sequence/Text";
import Seq "mo:sequence/Sequence";
import Stream "mo:sequence/Stream";

import RedrawTypes "mo:redraw/Types";

module {

public type Dir2D = {
  #up;
  #down;
  #left;
  #right
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

// input events (from local terminal to remote service)
public type Event = RedrawTypes.Event.Event;
public type KeyInfo = RedrawTypes.Event.KeyInfo;

// graphical output (from remote service to local terminal)
public type Graphics = RedrawTypes.Graphics.Result;

}
