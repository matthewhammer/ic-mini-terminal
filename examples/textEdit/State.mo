import Types "Types";

import List "mo:base/List";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";

import Render "mo:redraw/Render";

import Stream "mo:sequence/Stream";
import TextSeq "mo:sequence/Text";
import Seq "mo:sequence/Sequence";

module {
  type State = Types.State;

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

  public func keyDownSeq(st:State, keys:[Types.KeyInfo]) {
    for (key in keys.vals()) { keyDown(st, key) };
  };

  public func update(st : State, events : [Types.EventInfo]) {
    for (ev in events.vals()) {
      st.currentEvent := ?ev;
      switch (ev.event) {
        case (#skip) { };
        case (#keyDown(keys)) keyDownSeq(st, keys);
        // ignore other events (for now):
        case (#quit) { };
        case (#mouseDown(_)) { };
        case (#windowSize(_)) { };
      };
    }
  };

  public func initState() : Types.State {
     {
       levels = Stream.Bernoulli.seedFrom(0);
       commitLog = Buffer.Buffer<Types.EventInfo>(0);
       var bwd = Seq.empty<Types.Elm>();
       var fwd = Seq.empty<Types.Elm>();
       var viewEvents = ([] : [Types.EventInfo]);
       var currentEvent = (null : ?Types.EventInfo);
     }
  };

  public func clone(st : State) : State {
    {
      levels = st.levels;
      commitLog = st.commitLog;
      var viewEvents = st.viewEvents;
      var currentEvent = st.currentEvent;
      var fwd = st.fwd;
      var bwd = st.bwd;
    }
  };

  // to do ---------------------------------------

  // moveVert moves (just) past the nearest newline character, forward or backward
  // (to do -- this behavior is good enough for now, but isn't what people expect).

  func elmText(elm : Types.Elm) : ?Text {
    switch elm {
      case (#text(te)) { ?te.text };
    }
  };

  func moveVert(st : State, dir : {#fwd; #bwd}) {
    var column : ?Nat = null;
    switch dir {
    case (#fwd) {
           switch (Seq.peekFront(st.fwd)) {
             case null { };
             case (?f) {
                    if (elmText(f) == ?"\n") {
                      move(st, #right)
                    }
                    else {
                      move(st, #right);
                      moveVert(st, dir)
                    }
                  };
           }
         };
    case (#bwd) {
           switch (Seq.peekBack(st.bwd)) {
             case null { };
             case (?b) {
                    if (elmText(b) == ?"\n") {
                      move(st, #left)
                    }
                    else {
                      move(st, #left);
                      moveVert(st, dir)
                    }
                  };
           }
         };
    }
  };

  func move(st : State, dir : Types.Dir2D) {
    switch dir {
      case (#left) {
             switch (Seq.popBack(st.bwd)) {
               case (?(bwd, l)) {
                      st.bwd := bwd;
                      st.fwd := Seq.pushFront(l, st.levels.next(), st.fwd)
                    };
               case null {
                      // to do -- cannot move; terminal bell?
                    };
             }
           };
      case (#right) {
             switch (Seq.popFront(st.fwd)) {
               case (?(l, fwd)) {
                      st.fwd := fwd;
                      st.bwd := Seq.pushBack(st.bwd, st.levels.next(), l)
                    };
               case null {
                      // to do -- cannot move; terminal bell?
                    };
             }
           };
      case (#up) { moveVert(st, #bwd) };
      case (#down) { moveVert(st, #fwd) };
    }
  };

  func insert(st : State, preElm : { #text : Text }) {
    let textElm : Types.Elm = #text {
      lastModifyTime = switch (st.currentEvent) {
        case null "?";
        case (?ev) ev.dateTimeUtc;
      };
      lastModifyUser = switch (st.currentEvent) {
        case null "?";
        case (?ev) ev.userInfo.userName;
      };
      color = switch (st.currentEvent) {
        case null (255, 100, 100); // "bright red"
        case (?ev) ev.userInfo.textColor.0;
      };
      text = switch preElm { case (#text(t)) { t } };
    };
    st.bwd := Seq.pushBack(st.bwd, st.levels.next(), textElm)
  };

  func delete(st : State, dir : {#fwd; #bwd}) {
    switch dir {
      case (#bwd) {
             switch (Seq.popBack(st.bwd)) {
               case (?(bwd, _)) { st.bwd := bwd };
               case _ { };
             }
           };
      case (#fwd) {
             switch (Seq.popFront(st.fwd)) {
               case (?(_, fwd)) { st.fwd := fwd };
               case _ { };
             }
           };
    }
  };

}
