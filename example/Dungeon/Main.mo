import Array "mo:base/Array";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Debug "mo:base/Debug";

import Types "Types";
import State "State";
import Draw "Draw";

actor {

  var state : Types.State = State.initState();

  /// attempt to "commit" a block of local events to the state's commitLog
  public func update(
    events : [Types.EventInfo],
    gfxReq: Types.GraphicsRequest) : async [Types.Graphics] 
  {
    let gfx = State.update(state, events, gfxReq);
    gfx
  };

  public query func view(
    windowDim : Render.Dim,
    events : [Types.EventInfo])
    : async Types.Graphics
  {
    let temp = State.clone(state);
    let _ = State.update(temp, events, #none);
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
