import Result "mo:base/Result";
import List "mo:base/List";
import Render "mo:redraw/Render";
import Types "Types";
import Array "mo:base/Array";

module {

  type State = Types.State;
  type Dir2D = Types.Dir2D;
  type Pos = Types.Pos;
  type Tile = Types.Tile;
  type Player = Types.PlayerState;

  public func clonePlayer(pst:Player) : Player {
    {
      var keys = pst.keys;
      var pos  = pst.pos;
    }
  };

  public func clone(st:State) : State {
    {
      var maze = st.maze ;
      var won = st.won ;
      var player = Array.transform(st.player, clonePlayer);
    }
  };

  public func keyDown(st:State, playerId:Nat, key:Types.KeyInfo) {
    let r = switch (key.key) {
      case "ArrowLeft"  move(st, playerId, #left);
      case "ArrowRight" move(st, playerId, #right);
      case "ArrowUp"    move(st, playerId, #up);
      case "ArrowDown"  move(st, playerId, #down);
      case _  { #err(()) };
    };
    // ignore errors for now
    switch r {
    case (#ok) { };
    case (#err) { };
    }
  };

  public func keyDownSeq(st:State, pid:Nat, keys:[Types.KeyInfo]) {
    for (key in keys.vals()) { keyDown(st, pid, key) };
  };

  public func getTile(st:State, pos:Pos) : ?Tile {
    let room = st.maze.rooms[pos.room];
    // address y pos (row), then x pos (column):
    if (pos.tile.1 < room.height and pos.tile.0 < room.width) {
      let tile = room.tiles[pos.tile.1][pos.tile.0];
      ?tile
    } else {
      null
    }
  };

  public func setTile(st:State, pos:Pos, newTile:Tile) : ?Tile {
    let room = st.maze.rooms[pos.room];
    // address y pos (row), then x pos (column): 
    if (pos.tile.1 < room.height and pos.tile.0 < room.width) {
      let oldTile = room.tiles[pos.tile.1][pos.tile.0];
      room.tiles[pos.tile.1][pos.tile.0] := newTile;
      ?oldTile
    } else {
      null
    }
  };

  public func getNeighborTile(st:State, pid:Nat, dir:Dir2D) : ?Tile {
    getTile(st, movePos(st.player[pid - 1].pos, dir))
  };

  public func updateNeighborTile(st:State, pid:Nat, dir:Dir2D, tile:Tile) : ?Tile {
    setTile(st, movePos(st.player[pid - 1].pos, dir), tile)
  };

  public func posEq(pos1:Pos, pos2:Pos) : Bool {
    pos1.room == pos2.room and
    pos1.tile.0 == pos2.tile.0 and
    pos1.tile.1 == pos2.tile.1
  };

  public func move(st:State, pid:Nat, dir:Dir2D) : Result.Result<(), ()> {
    if (posEq(movePos(st.player[pid - 1].pos, dir), st.player[pid - 1].pos)) {
      return #err(())
    };
    switch (getNeighborTile(st, pid, dir)) {
      case null {
             #err(())
           };
      case (?#floor) {
             st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
             #ok(())
           };
      case (?#key(id)) {
             switch id {
               case null {
                      ignore updateNeighborTile(st, pid, dir, #floor);
                      st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
                      st.player[pid - 1].keys := ?(id, st.player[pid - 1].keys);
                      #ok(())
                    };
               case (?x) {
                      if (x == pid) {
                        // take the key ==> the key is replaced with floor
                        ignore updateNeighborTile(st, pid, dir, #floor);
                        st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
                        st.player[pid - 1].keys := ?(id, st.player[pid - 1].keys);
                        #ok(())
                      } else {
                        // not our key ==> walk over key, but key stays in maze
                        st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
                        #ok(())
                      }
                    };
           }
           };
      case (?#lock(id)) {
             switch (st.player[pid - 1].keys) {
             case null { #err(()) };
             case (?(_key, keys)) {
                    switch _key {
                      case null { assert true };
                      case (?x) { assert (pid == x) };
                    };
                    ignore updateNeighborTile(st, pid, dir, #floor);
                    // use last key; to do: search for matching keys by Id...
                    st.player[pid - 1].keys := keys;
                    st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
                    #ok(())
                  };
             }
           };
      case (?#wall) {
             #err(())
           };
      case (?#void) {
             #err(())
           };
      case (?#goal) {
             st.won := true;
             st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
             #ok(())
           };
      case (?#start) {
             st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
             #ok(())
           };
      case (?#outward(newPos)) {
             // teleport!
             st.player[pid - 1].pos := newPos;
             #ok(())
           };
      case (?#inward(_)) {
             st.player[pid - 1].pos := movePos(st.player[pid - 1].pos, dir);
             #ok(())
           };
    }
  };

  public func movePos(pos:Pos, dir:Dir2D) : Pos {
    let (xPos, yPos) = (pos.tile.0, pos.tile.1);
    let newTilePos = switch dir {
    case (#up) { (xPos, if (yPos > 0) {yPos-1} else { 0 }) };
    case (#down) { (xPos, yPos+1) };
    case (#left) { (if (xPos > 0) {xPos - 1} else { 0 }, yPos) };
    case (#right) { (xPos+1, yPos) };
    };
    { room= pos.room;
      tile=newTilePos }
  };

  public func multiMove(st:State, pid:Nat, dirs:[Dir2D]) : Result.Result<(), ()> {
    for (dir in dirs.vals()) {
      switch (move(st, pid, dir)) {
        case (#ok(())) { };
        case (#err(())) { return #err(()) };
      };
    };
    #ok(())
  };

  public func initState() : Types.State {
    // tile palette for example maze
    let x = #void;
    let s = #start;
    let g = #goal;
    let f = #floor;
    let w = #wall;
    let l = #lock(null);
    let k = #key(null);
    let i = #inward;

    let startPos = { room = 0;
                     tile = (1, 1) };

    let p1 : Tile = #outward{room=1;tile=(4, 1)};
    let room0Tiles : [[ var Tile ]] = [
      [ var x, w, x, x, x ],
      [ var w, s, w, w, x ],
      [ var w, f, f, p1,w ],
      [ var x, w, k, w, x ],
      [ var x, x, w, x, x ],
    ];

    let p2 : Tile = #outward{room=2;tile=(1, 1)};
    let p0 : Tile = #outward{room=0;tile=(1, 1)};
    let room1Tiles : [[ var Tile ]] = [
      [ var x, x, w, w, w, w ],
      [ var w, w, f, l, i, w ],
      [ var w, k, f, w, f, w ],
      [ var w, k, f, w, f, w ],
      [ var w, p2,f, w, f, w ],
      [ var w, w, w, w, p0,w ],
      [ var x, x, x, x, w, x ],
    ];

    let room2Tiles : [[ var Tile ]] = [
      [ var x, w, w, w,  x, x, x, x,  x, x, x, x ],
      [ var w, i, f, p0, w, x, x, x,  x, w, w, w ],
      [ var w, f, w, w,  x, x, w, x,  w, l, l, g ],
      [ var w, l, w, x,  x, w, f, w,  w, l, w, w ],
      [ var w, k, w, x,  x, w, f, f,  f, l, f, w ],
      [ var w, k, w, x,  w, w, l, w,  f, f, f, w ],
      [ var w, l, w, x,  w, l, f, w,  w, f, f, w ],
      [ var w, l, w, x,  w, l, l, w,  x, w, f, w ],
      [ var w, l, w, w,  w, l, f, w,  x, w, f, w ],
      [ var w, f, f, f,  l, f, f, w,  w, f, f, w ],
      [ var w, f, w, w,  w, w, f, w,  k, k, f, w ],
      [ var w, f, k, w,  k, k, f, w,  k, k, f, w ],
      [ var x, w, w, w,  w, w, w, x,  w, w, w, x ],
    ];
    
    let maze_ : Types.Maze = {
      start = startPos;
      rooms = [
        {
          width=5;
          height=5;
          tiles=room0Tiles;
        },
        {
          width=6;
          height=7;
          tiles=room1Tiles;
        },
        {
          width=12;
          height=13;
          tiles=room2Tiles;
        }
      ]
    }; 
    // to do -- this let binding should be permitted in the record below
    let noKeys : List.List<?Nat> = null;
    {
      var player = [
        { var keys = noKeys; var pos = startPos } : Types.PlayerState,
        { var keys = noKeys; var pos = startPos } : Types.PlayerState
      ];
      var won = false;
      var maze : Types.Maze = maze_
    }
  };
}
