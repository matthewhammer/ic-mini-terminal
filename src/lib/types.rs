/// Types of data sent to and from the game server canister.

pub type Nat = candid::Nat;
pub type Int = candid::Int;

pub mod lang {
    use super::Nat;
    use hashcons::merkle::Merkle;
    use serde::{Deserialize, Serialize};
    use candid::CandidType;

    #[derive(Debug, Clone, CandidType, Eq, PartialEq, Hash)]
    pub enum Name {
        Void,
        Atom(Atom),
        TaggedTuple(Box<Name>, Vec<Name>),
        Merkle(Merkle<Name>),
    }

    #[derive(Debug, Clone, CandidType, Eq, PartialEq, Hash)]
    pub enum Atom {
        Bool(bool),
        Nat(Nat),
        String(String),
    }
}

pub mod event {
    use super::Nat;
    use serde::{Deserialize, Serialize};
    use candid::CandidType;

    #[derive(Clone, Debug, CandidType, Hash, PartialEq, Eq)]
    pub enum Event {
        Quit,
        KeyDown(KeyEventInfo),
        KeyUp(KeyEventInfo),
        WindowSizeChange(super::render::Dim),
    }
    #[derive(Clone, Debug, CandidType, Hash, PartialEq, Eq]
    pub struct KeyEventInfo {
        pub key: String,
        pub alt: bool,
        pub ctrl: bool,
        pub meta: bool,
        pub shift: bool,
    }
}

pub mod render {
    use super::{Nat, Int};
    use super::lang::Name;
    use serde::{Deserialize, Serialize};
    use candid::CandidType;

    pub type Color = (Nat, Nat, Nat);

    #[derive(Clone, Debug, CandidType, Hash, PartialEq, Eq)]
    pub struct Dim {
        pub width: Nat,
        pub height: Nat,
    }
    #[derive(Clone, Debug, CandidType, Hash, PartialEq, Eq)]
    pub struct Pos {
        pub x: Int,
        pub y: Int,
    }
    #[derive(Clone, Debug, CandidType, Hash, PartialEq, Eq)]
    pub struct Rect {
        pub pos: Pos,
        pub dim: Dim,
    }
    impl Rect {
        pub fn new(x: Int, y: Int, w: Nat, h: Nat) -> Rect {
            Rect {
                pos: Pos { x, y },
                dim: Dim {
                    width: w,
                    height: h,
                },
            }
        }
    }
    #[derive(Clone, Debug, CandidType, Hash, PartialEq, Eq)]
    pub struct Node {
        pub name: Name,
        pub rect: Rect,
        pub fill: Fill,
        pub children: Elms,
    }
    #[derive(Clone, Debug, CandidType, Serialize, Deserialize, Hash, PartialEq, Eq)]
    pub enum Fill {
        #[serde(rename(serialize = "open", deserialize = "open"))]
        Open(Color, Nat), // border width
        #[serde(rename(serialize = "closed", deserialize = "closed"))]
        Closed(Color),
        #[serde(rename(serialize = "none", deserialize = "none"))]
        None,
    }
    #[derive(Clone, Debug, CandidType, Serialize, Deserialize, Hash, PartialEq, Eq)]
    pub enum Elm {
        #[serde(rename(serialize = "rect", deserialize = "rect"))]
        Rect(Rect, Fill),
        #[serde(rename(serialize = "node", deserialize = "node"))]
        Node(Box<Node>),
    }
    pub type Elms = Vec<Elm>;
    pub type NamedElms = Vec<(Name, Elm)>;

    #[derive(Clone, Debug, CandidType, Serialize, Deserialize, Hash, PartialEq, Eq)]
    pub enum Out {
        #[serde(rename(serialize = "draw", deserialize = "draw"))]
        Draw(Elm),
        #[serde(rename(serialize = "redraw", deserialize = "redraw"))]
        Redraw(NamedElms),
    }

    #[derive(Clone, Debug, CandidType, Serialize, Deserialize, Hash, PartialEq, Eq)]
    pub enum Result {
        #[serde(rename(serialize = "ok", deserialize = "ok"))]
        Ok(Out),
        #[serde(rename(serialize = "err", deserialize = "err"))]
        Err(Out),
    }
}
