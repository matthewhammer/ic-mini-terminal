import List "mo:base/List";
import Buffer "mo:base/Buffer";
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
  // to do: per-user cursors (another case here).
};

public type TextElm = {
  lastModifyUser: Text;
  lastModifyTime: Text; // use [ISO8601](https://tools.ietf.org/html/rfc3339)
  color : Render.Color;
  text : Text;
};

public type Levels = Seq.Stream<Stream.Bernoulli.Value>;
public type Content = Seq.Sequence<Elm>;

public type State = {
  levels : Levels;

  commitLog : Buffer.Buffer<EventInfo>;

  var fwd : Content;
  var bwd : Content;

  var viewEvents : [EventInfo];
  var currentEvent : ?RedrawTypes.Event.EventInfo;
};

// input events (from local terminal to remote service)
public type EventInfo = RedrawTypes.Event.EventInfo;
public type KeyInfo = RedrawTypes.Event.KeyInfo;

// graphical output (from remote service to local terminal)
public type Graphics = RedrawTypes.Graphics.Result;

}
