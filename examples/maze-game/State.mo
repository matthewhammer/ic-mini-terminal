import Result "mo:base/Result";
import List "mo:base/List";
import Render "../../src/Render";
import Types "Types";

module {
  
  type State = Types.State;
  type Dir2D = Types.Dir2D;
  type Pos = Types.Pos;
  type Tile = Types.Tile;

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

  public func getNeighborTile(st:State, dir:Dir2D) : ?Tile {
    getTile(st, movePos(st.pos, dir))
  };

  public func updateNeighborTile(st:State, dir:Dir2D, tile:Tile) : ?Tile {
    setTile(st, movePos(st.pos, dir), tile)
  };

  public func posEq(pos1:Pos, pos2:Pos) : Bool {
    pos1.room == pos2.room and
    pos1.tile.0 == pos2.tile.0 and 
    pos1.tile.1 == pos2.tile.1
  };

  public func move(st:State, dir:Dir2D) : ?() {
    do ? {
      if (posEq(movePos(st.pos, dir), st.pos)) {
        return null
      };
      switch (getNeighborTile(st, dir)) {
      case null { return null };
      case (?#floor) {
        st.pos := movePos(st.pos, dir);
      };
      case (?#key(id)) {
        ignore(updateNeighborTile(st, dir, #floor)!);
        st.pos := movePos(st.pos, dir);
        st.keys := ?(id, st.keys);
      };
      case (?#lock(id)) {
        switch (st.keys) {
          case null { return null };
          case (?(_key, keys)) { 
            ignore(updateNeighborTile(st, dir, #floor)!);
            // use last key; to do: search for matching keys by Id...
            st.keys := keys; 
            st.pos := movePos(st.pos, dir);
          };
        }
      };
      case (?#wall) { return null };
      case (?#void) { return null };
      case (?#goal) {
        st.won := true;
        st.pos := movePos(st.pos, dir);
      };
      case (?#start) {
        st.pos := movePos(st.pos, dir);
      };
      case (?#outward(newPos)) {
        // teleport!
        st.pos := newPos;
      };
      case (?#inward(_)) {
        st.pos := movePos(st.pos, dir);
      };
      }
    }
  };
  
  public func movePos(pos:Pos, dir:Dir2D) : Pos {
    let (xPos, yPos) = (pos.tile.0, pos.tile.1);
    let newTilePos = switch dir {
    case (#up) { (xPos, if (yPos > 0) {yPos - 1 : Nat} else { 0 }) };
    case (#down) { (xPos, yPos+1) };
    case (#left) { (if (xPos > 0) {xPos - 1 : Nat} else { 0 }, yPos) };
    case (#right) { (xPos+1, yPos) };
    };
    { room= pos.room;
      tile=newTilePos }
  };

  public func clone(st : State) : State {
    { var keys = st.keys ;
      var maze = st.maze ;
      var pos = st.pos ;
      var won = st.won }
  };
  
  public func initState() : Types.State {
    // tile palette for example maze
    let x = #void;
    let s = #start;
    let g = #goal;
    let f = #floor;
    let w = #wall;
    let l = #lock;
    let k = #key;
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
    { 
      var keys = List.nil<()>();
      var won = false;
      var pos = startPos;
      var maze : Types.Maze = 
        {
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
          ];
        }
    }
  };
}
