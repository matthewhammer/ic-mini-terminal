/// Types of data sent to and from the game server canister.

pub type Nat = candid::Nat;

pub mod lang {
    use super::Nat;
    //use hashcons::merkle::Merkle;
    use candid::{CandidType, Deserialize};

    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Dir2D {
        #[serde(rename(deserialize = "up"))]
        Up,
        #[serde(rename(deserialize = "down"))]
        Down,
        #[serde(rename(deserialize = "left"))]
        Left,
        #[serde(rename(deserialize = "right"))]
        Right,
    }

    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Name {
        Void,
        Atom(Atom),
        TaggedTuple(Box<Name>, Vec<Name>),
        //Merkle(Merkle<Name>),
    }

    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Atom {
        Bool(bool),
        Nat(Nat),
        String(String),
    }
}

/// Game terminal to game server:
///
/// Information from Rust event loop (via SDL2) to Motoko canister logic.
pub mod event {
    use candid::{CandidType, Deserialize};

    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Event {
        #[serde(rename(serialize = "quit"))]
        Quit,
        #[serde(rename(serialize = "keyDown"))]
        KeyDown(Vec<KeyEventInfo>),
        #[serde(rename(serialize = "mouseDown"))]
        MouseDown(super::render::Pos),
        #[serde(rename(serialize = "windowSize"))]
        WindowSize(super::render::Dim),
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct KeyEventInfo {
        pub key: String,
        pub alt: bool,
        pub ctrl: bool,
        pub meta: bool,
        pub shift: bool,
    }
}

/// Game server to game terminal:
///
/// Information from Motoko canister logic to Rust graphics output (via SDL2).
pub mod render {
    use super::Nat;
    //use super::lang::Name;
    use candid::{CandidType, Deserialize};

    pub type Color = (Nat, Nat, Nat);

    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Dim {
        pub width: Nat,
        pub height: Nat,
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Pos {
        pub x: Nat,
        pub y: Nat,
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Rect {
        pub pos: Pos,
        pub dim: Dim,
    }
    impl Rect {
        pub fn new(x: Nat, y: Nat, w: Nat, h: Nat) -> Rect {
            Rect {
                pos: Pos { x, y },
                dim: Dim {
                    width: w,
                    height: h,
                },
            }
        }
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Node {
        pub rect: Rect,
        pub fill: Fill,
        pub elms: Elms,
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Fill {
        #[serde(rename(deserialize = "open"))]
        Open(Color, Nat), // border width
        #[serde(rename(deserialize = "closed"))]
        Closed(Color),
        #[serde(rename(deserialize = "none"))]
        None,
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Elm {
        #[serde(rename(deserialize = "rect"))]
        Rect(Rect, Fill),
        #[serde(rename(deserialize = "node"))]
        Node(Box<Node>),
        #[serde(rename(deserialize = "text"))]
        Text(String, TextAtts),
    }
    pub type Elms = Vec<Elm>;
    pub type NamedElms = Vec<(String, Elm)>;

    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct TextAtts {
        pub zoom: Nat,
        #[serde(rename(deserialize = "fgFill"))]
        pub fg_fill: Fill,
        #[serde(rename(deserialize = "bgFill"))]
        pub bg_fill: Fill,
        #[serde(rename(deserialize = "glyphDim"))]
        pub glyph_dim: Dim,
        #[serde(rename(deserialize = "glyphFlow"))]
        pub glyph_flow: FlowAtts,
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct FlowAtts {
        pub dir: super::lang::Dir2D,
        #[serde(rename(deserialize = "intraPad"))]
        pub intra_pad: Nat,
        #[serde(rename(deserialize = "interPad"))]
        pub inter_pad: Nat,
    }

    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Out {
        #[serde(rename(deserialize = "draw"))]
        Draw(Elm),
        #[serde(rename(deserialize = "redraw"))]
        Redraw(NamedElms),
    }

    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Result {
        #[serde(rename(deserialize = "ok"))]
        Ok(Out),
        #[serde(rename(deserialize = "err"))]
        Err(Out),
    }
}
