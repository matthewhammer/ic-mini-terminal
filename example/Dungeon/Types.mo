import List "mo:base/List";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";

import Render "mo:redraw/Render";
import RedrawTypes "mo:redraw/Types";

module {

// input events (from local terminal to remote service)
public type EventInfo = RedrawTypes.Event.EventInfo;
public type KeyInfo = RedrawTypes.Event.KeyInfo;

// graphical output (from remote service to local terminal)
public type Graphics = RedrawTypes.Graphics.Result;
public type GraphicsElm = RedrawTypes.Graphics.Elm;
public type GraphicsRequest = RedrawTypes.GraphicsRequest;

public type UserState = {
  name : Text;
  textColor : Render.Color;
  lastEventTime : Text;
};

public type State = {
  users : TrieMap.TrieMap<Text, UserState>;
};

public type Dir2D = {#up; #down; #left; #right};

}
