import List "mo:base/List";
import Result "mo:base/Result";
import Render "mo:redraw/Render";

module {

public type KeyInfo = {
  key : Text;
  alt : Bool;
  ctrl : Bool;
  meta: Bool;
  shift: Bool
};

public type Tile = {
  #void;
  #start;
  #goal;
  #floor;
  #wall;
  #lock : KeyUser;
  #key : KeyUser;
  #inward;
  #outward : Pos;
};

/// KeyUser: `null` means "all players", and `?n` means "only player n"
public type KeyUser = ?PlayerId;

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

public type PlayerId = Nat;

// player state (for players 1 and 2)
public type PlayerState = {
  var keys: List.List<KeyUser>;
  var pos: Pos;
};

// full game state:
public type State = {
  var player: [PlayerState];
  var maze: Maze;
  var won: Bool;
};

// move results back to game client:
public type ResOut = Result.Result<Render.Out, Render.Out>;

}
