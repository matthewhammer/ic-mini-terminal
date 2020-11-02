import Array "mo:base/Array";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Types "Types";
import State "State";
import Draw "Draw";
import Debug "mo:base/Debug";

actor {

  flexible var state = State.initState();

  public func init(userName : Text, userTextColor : Render.Color) {
    State.init(state, userName, userTextColor)
  };

  public func update(events : [Types.EventInfo]) {
    State.update(state, events)
  };

  public query func view(
    windowDim : Render.Dim,
    events : [Types.EventInfo])
    : async Types.Graphics
  {
    let temp = State.clone(state);
    State.update(temp, events);
    redrawScreen(windowDim, temp)
  };

  func redrawScreen(
    windowDim : Render.Dim,
    state : Types.State)
    : Types.Graphics
  {
    let elm = Draw.drawState(state, windowDim);
    #ok(#redraw([("screen", elm)]))
  }

};
