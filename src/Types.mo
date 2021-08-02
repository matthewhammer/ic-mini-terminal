module {

  public type GraphicsRequest = {
    #none;
    #all : Dim;
    #last : Dim;
  };

  public type Dim = { width: Nat;
                      height: Nat };

  public type Pos = { x:Nat;
                      y:Nat };

  public type Rect = { pos:Pos;
                       dim:Dim };

  public module Event {

    public type UserInfo = {
      userName: Text;
      textColor: (
        (Nat, Nat, Nat),
        (Nat, Nat, Nat)
      )
    };

    public type EventInfo = {
      userInfo: UserInfo;
      nonce: ?Nat;
      dateTimeUtc: Text;   // use [ISO8601](https://tools.ietf.org/html/rfc3339)
      dateTimeLocal: Text; // use [ISO8601](https://tools.ietf.org/html/rfc3339)
      event: Event;
    };

    public type Event = {
      #skip;
      #quit;
      #keyDown : [KeyInfo];
      #mouseDown : Pos;
      #windowSize : Dim;
      #clipBoard : Text;
      #fileRead : {path: Text; content: Text};
    };

    public type KeyInfo = {
      key : Text;
      alt : Bool;
      ctrl : Bool;
      meta: Bool;
      shift: Bool
    };
  };

  public module Graphics {

    public type Color = (Nat, Nat, Nat);

    public type Node = { rect: Rect;
                         fill: Fill;
                         elms: Elms };

    public type Elm = { #rect: (Rect, Fill);
                        #node: Node };

    public type Fill = {#open: (Color, Nat);
                        #closed: Color;
                        #none};

    public type Elms = [Elm];

    public type Out = {
      #draw:Elm;
      #redraw:[(Text, Elm)];
    };

    public type Result = {
      #ok: Out;
      #err: ?Text;
    };

  };

}
