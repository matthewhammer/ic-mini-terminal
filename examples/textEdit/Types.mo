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
  #text : TextElm
  // more to come, in the future.
};

public type TextElm = {
  lastModifyUser: Text;
  lastModifyTime: Text; // use [ISO8601](https://tools.ietf.org/html/rfc3339)
  color : Render.Color;
  text : Text;
  //time : Nat; -- to do, later.
};

public type Levels = Seq.Stream<Stream.Bernoulli.Value>;
public type Content = Seq.Sequence<Elm>;

public type Init = {
  userName : Text;
  userTextColor : Render.Color;
};

public type State = {
  levels : Levels;
  var init : Init;
  var fwd : Content;
  var bwd : Content;  
  var currentEvent : ?RedrawTypes.Event.EventInfo;
};

// input events (from local terminal to remote service)
public type EventInfo = RedrawTypes.Event.EventInfo;
public type KeyInfo = RedrawTypes.Event.KeyInfo;

// graphical output (from remote service to local terminal)
public type Graphics = RedrawTypes.Graphics.Result;

}
