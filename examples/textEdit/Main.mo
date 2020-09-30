import Array "mo:base/Array";
import Result "mo:base/Result";
import Render "mo:redraw/Render";
import Types "Types";
import State "State";
import Draw "Draw";
import Debug "mo:base/Debug";

actor {
  
  flexible var state = State.initState();

  flexible var windowDim : Render.Dim = {
    width = 100;
    height = 100;
  };

  public func windowSizeChange(dim:Render.Dim) : async Types.ResOut {
    Debug.print "windowSizeChange";
    Debug.print (debug_show dim);
    windowDim := dim;
    redrawScreen(state, false, #ok)
  };

  public func updateKeyDown(keys:[Types.KeyInfo]) : async Types.ResOut {
    Debug.print "updateKeyDown";
    State.keyDownSeq(state, keys);
    redrawScreen(state, false, #ok)
  };

  public query func queryKeyDown(keys:[Types.KeyInfo]) : async Types.ResOut {
    Debug.print "queryKeyDown";
    let temp = State.clone(state);
    State.keyDownSeq(temp, keys);
    redrawScreen(temp, true, #ok)
  };

  func redrawScreen(state:Types.State, isQueryView:Bool, status:{#ok; #err}) : Types.ResOut {
    // to do -- use the window dimensions in the drawing logic (?)
    let elm = Draw.drawState(state, isQueryView);
    let rs : Render.Out = #redraw([("screen", elm)]);
    switch status {
      case (#ok) { #ok(rs) };
      case (#err) { #err(rs) };
    }
  }
  
};
