import Nat "mo:base/Nat";

import TermTypes "../../src/Types";
import Term "../../src/terminal/Terminal";
import Render "../../src/Render";

import Types "Types";
import State "State";
import Draw "Draw";
  
actor {

  type Dim = Term.Dim;
  type Elm = Term.Elm;
  type EventInfo = Term.EventInfo;

  class MazeGame(initState : Types.State) {
     
    var state = initState;

    public func clone () : MazeGame {
      MazeGame(state)
    };

    public func draw (d: Dim) : Elm {
      Draw.drawState(state)
    };

    public func update (e : EventInfo) {
      let res = do ? { switch (e.event) {
        case (#keyDown(keys)) {
          for (k in keys.vals()) {
            switch (k.key) {
              case "ArrowUp" { State.move(state, #up)! };
              case "ArrowDown" { State.move(state, #down)! };
              case "ArrowLeft" { State.move(state, #left)! };
              case "ArrowRight" { State.move(state, #right)! };
              case _ { /* ignore key */ };
            }
          }
        };
        case _ { /* ignore event */ };
      } };
      ignore res
    };
  };

  func _subTypeCheck(mg : MazeGame) : Term.Core {
    mg
  };

  func initTerm() : Term.Terminal {
    Term.Basic(MazeGame(State.initState()))
  };

  var term = initTerm();

  public func reset() : async ?() {
    term := initTerm();
    ?()
  };

  public query func view(dim : Dim, events : [EventInfo]) : async Term.ViewResult {
    term.view(dim, events)
  };

  public func update(events : [EventInfo], gfxReq : Term.GfxReq) : async Term.UpdateResult {
    term.update(events, gfxReq)
  };

}
