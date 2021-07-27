import Types "Types";

import List "mo:base/List";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";

import Draw "Draw";

module {
  type State = Types.State;

  public func keyDownSeq(st:State, keys:[Types.KeyInfo]) {
    for (key in keys.vals()) { keyDown(st, key) };
  };

  public func updateUsers(st : State, event : Types.EventInfo) {
    st.users.put(event.userInfo.userName,
                 {
                   name = event.userInfo.userName ;
                   textColor = event.userInfo.textColor.0 ;
                   lastEventTime = event.dateTimeLocal ;
                 });
  };

  public func update(st : State,
                     events : [Types.EventInfo],
                     gfxReq : Types.GraphicsRequest)
  : [Types.Graphics]
  {
    func gfxOut(elm : Types.GraphicsElm) : Types.Graphics =
      #ok(#redraw([("screen", elm)]));

    let gfx = Buffer.Buffer<Types.Graphics>(0);
    for (ev in events.vals()) {
      updateUsers(st, ev);
      switch (ev.event) {
        case (#skip) { };
        case (#keyDown(keys)) keyDownSeq(st, keys);
        // ignore other events (for now):
        case (#quit) { };
        case (#mouseDown(_)) { };
        case (#windowSize(_)) { };
        case (#clipBoard(_)) { };
        case (#fileRead(_)) { };
      };
      switch gfxReq {
      case (#none) { };
      case (#last _) { };
      case (#all dim) { gfx.add(gfxOut(Draw.drawState(st, dim))) };
      }
    };
    switch gfxReq {
    case (#none) { };
    case (#last dim) { gfx.add(gfxOut(Draw.drawState(st, dim))) };
    case (#all _) { };
    };
    gfx.toArray()
  };

  public func initState() : Types.State {
     {
       users = TrieMap.TrieMap<Text, Types.UserState>(Text.equal, Text.hash);
     }
  };

  public func clone(st : State) : State {
    {
      users = TrieMap.clone<Text, Types.UserState>(st.users, Text.equal, Text.hash);
    }
  };

  func delete(st : State, dir : {#fwd; #bwd}) {
    // to do
  };

  func insert(st : State, preElm : { #text : Text }) {
    // to do
  };

  func move(st : State, dir : Types.Dir2D) {
    switch dir {
      case (#left) {
        // to do
      };
      case (#right) {
        // to do
      };
      case (#up) {
        // to do
      };
      case (#down) {
        // to do
      };
    }
  };

  public func keyDown(st:State, key:Types.KeyInfo) {
    switch (key.key) {
      case "ArrowLeft"  move(st, #left);
      case "ArrowRight" move(st, #right);
      case "ArrowUp"    move(st, #up);
      case "ArrowDown"  move(st, #down);
      case "Backspace"  delete(st, #bwd);
      case "Delete"     delete(st, #fwd);
      case "Tab" insert(st, #text("\t"));
      case " " insert(st, #text(" "));
      case "Enter" insert(st, #text("\n"));
      case "?" insert(st, #text("?"));
      case "/" insert(st, #text("/"));
      case "\\" insert(st, #text("\\"));
      case "." insert(st, #text("."));
      case "," insert(st, #text(","));
      case "<" insert(st, #text("<"));
      case ">" insert(st, #text(">"));
      case "(" insert(st, #text("("));
      case ")" insert(st, #text(")"));
      case "[" insert(st, #text("["));
      case "]" insert(st, #text("]"));
      case "{" insert(st, #text("{"));
      case "}" insert(st, #text("}"));
      case ":" insert(st, #text(":"));
      case ";" insert(st, #text(";"));
      case "`" insert(st, #text("`"));
      case "'" insert(st, #text("'"));
      case "\"" insert(st, #text("\""));
      case "~" insert(st, #text("~"));
      case "!" insert(st, #text("!"));
      case "@" insert(st, #text("@"));
      case "#" insert(st, #text("#"));
      case "$" insert(st, #text("$"));
      case "%" insert(st, #text("%"));
      case "^" insert(st, #text("^"));
      case "&" insert(st, #text("&"));
      case "*" insert(st, #text("*"));
      case "_" insert(st, #text("_"));
      case "-" insert(st, #text("-"));
      case "+" insert(st, #text("+"));
      case "=" insert(st, #text("="));
      case "0" insert(st, #text("0"));
      case "1" insert(st, #text("1"));
      case "2" insert(st, #text("2"));
      case "3" insert(st, #text("3"));
      case "4" insert(st, #text("4"));
      case "5" insert(st, #text("5"));
      case "6" insert(st, #text("6"));
      case "7" insert(st, #text("7"));
      case "8" insert(st, #text("8"));
      case "9" insert(st, #text("9"));
      case "A" insert(st, #text("A"));
      case "a" insert(st, #text("a"));
      case "B" insert(st, #text("B"));
      case "b" insert(st, #text("b"));
      case "C" insert(st, #text("C"));
      case "c" insert(st, #text("c"));
      case "D" insert(st, #text("D"));
      case "d" insert(st, #text("d"));
      case "E" insert(st, #text("E"));
      case "e" insert(st, #text("e"));
      case "F" insert(st, #text("F"));
      case "f" insert(st, #text("f"));
      case "G" insert(st, #text("G"));
      case "g" insert(st, #text("g"));
      case "H" insert(st, #text("H"));
      case "h" insert(st, #text("h"));
      case "I" insert(st, #text("I"));
      case "i" insert(st, #text("i"));
      case "J" insert(st, #text("J"));
      case "j" insert(st, #text("j"));
      case "K" insert(st, #text("K"));
      case "k" insert(st, #text("k"));
      case "L" insert(st, #text("L"));
      case "l" insert(st, #text("l"));
      case "M" insert(st, #text("M"));
      case "m" insert(st, #text("m"));
      case "O" insert(st, #text("O"));
      case "o" insert(st, #text("o"));
      case "N" insert(st, #text("N"));
      case "n" insert(st, #text("n"));
      case "P" insert(st, #text("P"));
      case "p" insert(st, #text("p"));
      case "Q" insert(st, #text("Q"));
      case "q" insert(st, #text("q"));
      case "R" insert(st, #text("R"));
      case "r" insert(st, #text("r"));
      case "S" insert(st, #text("S"));
      case "s" insert(st, #text("s"));
      case "T" insert(st, #text("T"));
      case "t" insert(st, #text("t"));
      case "U" insert(st, #text("U"));
      case "u" insert(st, #text("u"));
      case "V" insert(st, #text("V"));
      case "v" insert(st, #text("v"));
      case "W" insert(st, #text("W"));
      case "w" insert(st, #text("w"));
      case "X" insert(st, #text("X"));
      case "x" insert(st, #text("x"));
      case "Y" insert(st, #text("Y"));
      case "y" insert(st, #text("y"));
      case "Z" insert(st, #text("Z"));
      case "z" insert(st, #text("z"));
      case _ { };
    };
  };

}
