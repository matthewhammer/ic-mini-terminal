import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";

module {

public type Tile = {
  #void;
  #start;
  #goal;
  #floor;
  #wall;
  #lock;
  #key;
  #inward;
  #outward : Pos;
};

public type Room = {
  width : Nat;
  height : Nat;
  tiles : [[var Tile]];
};

public type Pos = {
  room : Nat;
  tile : (Nat, Nat);
};

public type Maze = {
  start : Pos;
  rooms : [Room];
};

public type Dir2D = {#up; #down; #left; #right};

// full game state:
public type State = {
  var keys: List.List<()>;
  var maze: Maze;
  var pos: Pos;
  var won: Bool;
};

// move results back to game client:
public type ResOut = Result.Result<Render.Out, Render.Out>;

}
