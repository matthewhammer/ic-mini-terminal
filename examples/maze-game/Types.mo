import List "mo:base/List";

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

/// Player movements as four directions in 2D
public type Dir2D = {
  #up;
  #down;
  #left;
  #right
};

// full game state:
public type State = {
  var keys: List.List<()>;
  var maze: Maze;
  var pos: Pos;
  var won: Bool;
};

}
