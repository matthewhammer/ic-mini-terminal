import Array "mo:base/Array";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Types "Types";
import State "State";
import Draw "Draw";
import Debug "mo:base/Debug";

actor {

  flexible var state = State.initState();

  public func update(events : [Types.Event]) {
    State.update(state, events)
  };

  public query func view(
    windowDim : Render.Dim,
    events : [Types.Event])
    : async Types.Graphics
  {
    let temp = State.clone(state);
    State.update(temp, events);
    redrawScreen(windowDim, temp)
  };

  func redrawScreen(
    windowDim : Render.Dim,
    state:Types.State)
    : Types.Graphics
  {
    let elm = Draw.drawState(state, windowDim);
    #ok(#redraw([("screen", elm)]))
  }

};
